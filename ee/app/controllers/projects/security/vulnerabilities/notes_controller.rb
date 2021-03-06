# frozen_string_literal: true

module Projects
  module Security
    module Vulnerabilities
      class NotesController < Projects::ApplicationController
        extend ::Gitlab::Utils::Override

        include SecurityDashboardsPermissions
        include NotesActions
        include NotesHelper
        include ToggleAwardEmoji

        before_action :not_found, unless: -> { project.first_class_vulnerabilities_enabled? }
        before_action :authorize_create_note!, only: [:create]

        private

        alias_method :vulnerable, :project

        def note
          @note ||= noteable.notes.find(params[:id])
        end
        alias_method :awardable, :note

        def vulnerability
          @vulnerability ||= @project.vulnerabilities.find(params[:vulnerability_id])

          return render_404 unless can?(current_user, :read_vulnerability, @vulnerability)

          @vulnerability
        end
        alias_method :noteable, :vulnerability

        def finder_params
          params.merge(last_fetched_at: last_fetched_at, target_id: vulnerability.id, target_type: 'vulnerability', project: @project)
        end

        override :note_serializer
        def note_serializer
          VulnerabilityNoteSerializer.new(project: project, noteable: noteable, current_user: current_user)
        end

        override :discussion_serializer
        def discussion_serializer
          DiscussionSerializer.new(project: project, noteable: noteable, current_user: current_user, note_entity: VulnerabilityNoteEntity)
        end
      end
    end
  end
end
