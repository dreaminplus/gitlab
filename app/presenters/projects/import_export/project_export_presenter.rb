# frozen_string_literal: true

module Projects
  module ImportExport
    class ProjectExportPresenter < Gitlab::View::Presenter::Delegated
      presents :project

      def project_members
        super + group_members.as_json(group_members_tree).each do |group_member|
          group_member['source_type'] = 'Project' # Make group members project members of the future import
        end
      end

      def as_json(*_args)
        self.respond_to?(:override_description) ? super.merge("description" => override_description) : super
      end

      private

      # rubocop: disable CodeReuse/ActiveRecord
      def group_members
        return [] unless current_user.can?(:admin_group, project.group)

        # We need `.where.not(user_id: nil)` here otherwise when a group has an
        # invitee, it would make the following query return 0 rows since a NULL
        # user_id would be present in the subquery
        # See http://stackoverflow.com/questions/129077/not-in-clause-and-null-values
        non_null_user_ids = project.project_members.where.not(user_id: nil).select(:user_id)
        GroupMembersFinder.new(project.group).execute.where.not(user_id: non_null_user_ids)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
