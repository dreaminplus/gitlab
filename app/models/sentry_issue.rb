# frozen_string_literal: true

class SentryIssue < ApplicationRecord
  belongs_to :issue

  validates :issue, uniqueness: true, presence: true
  validates :sentry_issue_identifier, presence: true

  validates_uniqueness_of :sentry_issue_identifier, scope: :issue_id

  after_create_commit :enqueue_sentry_sync_job

  def self.for_project_and_identifier(project, identifier)
    joins(:issue)
      .where(issues: { project_id: project.id })
      .find_by_sentry_issue_identifier(identifier)
  end

  def enqueue_sentry_sync_job
    ErrorTrackingIssueLinkWorker.perform_async(issue.id)
  end
end
