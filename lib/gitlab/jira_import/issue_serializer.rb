# frozen_string_literal: true

module Gitlab
  module JiraImport
    class IssueSerializer
      attr_reader :jira_issue, :project, :import_owner_id, :params, :formatter

      def initialize(project, jira_issue, import_owner_id, params = {})
        @jira_issue = jira_issue
        @project = project
        @import_owner_id = import_owner_id
        @params = params
        @formatter = Gitlab::ImportFormatter.new
      end

      def execute
        {
          iid: params[:iid],
          project_id: project.id,
          description: description,
          title: title,
          state_id: map_status(jira_issue.status.statusCategory),
          updated_at: jira_issue.updated,
          created_at: jira_issue.created,
          author_id: import_owner_id, # TODO: map actual author: https://gitlab.com/gitlab-org/gitlab/-/issues/210580
          label_ids: label_ids
        }
      end

      private

      def title
        "[#{jira_issue.key}] #{jira_issue.summary}"
      end

      def description
        body = []
        body << formatter.author_line(jira_issue.reporter.displayName)
        body << formatter.assignee_line(jira_issue.assignee.displayName) if jira_issue.assignee
        body << jira_issue.description
        body << MetadataCollector.new(jira_issue).execute

        body.join
      end

      def map_status(jira_status_category)
        case jira_status_category["key"].downcase
        when 'done'
          Issuable::STATE_ID_MAP[:closed]
        else
          Issuable::STATE_ID_MAP[:opened]
        end
      end

      # We already create labels in Gitlab::JiraImport::LabelsImporter stage but
      # there is a possibility it may fail or
      # new labels were created on the Jira in the meantime
      def label_ids
        return if jira_issue.fields['labels'].blank?

        Gitlab::JiraImport::HandleLabelsService.new(project, jira_issue.fields['labels']).execute
      end
    end
  end
end
