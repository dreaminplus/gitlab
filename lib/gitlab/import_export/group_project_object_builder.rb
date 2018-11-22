# frozen_string_literal: true

module Gitlab
  module ImportExport
    # Given a class, it finds or creates a new object
    # (initializes in the case of Label) at group or project level.
    # If it does not exist in the group, it creates it at project level.
    #
    # Example:
    #   `GroupProjectObjectBuilder.build(Label, label_attributes)`
    #    finds or initializes a label with the given attributes.
    #
    # It also adds some logic around Group Labels/Milestones for edge cases.
    class GroupProjectObjectBuilder
      def self.build(*args)
        Project.transaction do
          new(*args).find
        end
      end

      def initialize(klass, attributes)
        @klass = klass < Label ? Label : klass
        @attributes = attributes
        @group = @attributes['group']
        @project = @attributes['project']
      end

      def find
        find_object || @klass.create(project_attributes)
      end

      private

      def find_object
        @klass.where(where_clause).first
      end

      def where_clause
        @attributes.slice('title').map do |key, value|
          scope_clause = table[:project_id].eq(@project.id)
          scope_clause = scope_clause.or(table[:group_id].eq(@group.id)) if @group

          table[key].eq(value).and(scope_clause)
        end.reduce(:or)
      end

      def table
        @table ||= @klass.arel_table
      end

      def project_attributes
        @attributes.except('group').tap do |atts|
          if label?
            atts['type'] = 'ProjectLabel' # Always create project labels
          elsif milestone?
            if atts['group_id'] # Transform new group milestones into project ones
              atts['iid'] = nil
              atts.delete('group_id')
            else
              claim_iid
            end
          end
        end
      end

      def label?
        @klass == Label
      end

      def milestone?
        @klass == Milestone
      end

      # If an existing group milestone used the IID
      # claim the IID back and set the group milestone to use one available
      # This is necessary to fix situations like the following:
      #  - Importing into a user namespace project with exported group milestones
      #    where the IID of the Group milestone could conflict with a project one.
      def claim_iid
        # The milestone has to be a group milestone, as it's the only case where
        # we set the IID as the maximum. The rest of them are fixed.
        milestone = @project.milestones.find_by(iid: @attributes['iid'])

        return unless milestone

        milestone.iid = nil
        milestone.ensure_project_iid!
        milestone.save!
      end
    end
  end
end
