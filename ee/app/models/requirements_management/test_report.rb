# frozen_string_literal: true

module RequirementsManagement
  class TestReport < ApplicationRecord
    include Sortable
    include BulkInsertSafe

    belongs_to :requirement, inverse_of: :test_reports
    belongs_to :author, inverse_of: :test_reports, class_name: 'User'
    belongs_to :pipeline, class_name: 'Ci::Pipeline'
    belongs_to :build, class_name: 'Ci::Build'

    validates :requirement, :state, presence: true
    validate :validate_pipeline_reference

    enum state: { passed: 1, failed: 2 }

    scope :for_user_build, ->(user_id, build_id) { where(author_id: user_id, build_id: build_id) }

    class << self
      def persist_requirement_reports(build, ci_report)
        timestamp = Time.current

        if ci_report.all_passed?
          bulk_insert!(persist_all_requirement_reports_as_passed(build, timestamp))
        else
          bulk_insert!(persist_individual_reports(build, ci_report, timestamp))
        end
      end

      private

      def persist_all_requirement_reports_as_passed(build, timestamp)
        [].tap do |reports|
          build.project.requirements.opened.select(:id).find_each do |requirement|
            reports << build_report(state: :passed, requirement: requirement, build: build, timestamp: timestamp)
          end
        end
      end

      def persist_individual_reports(build, ci_report, timestamp)
        [].tap do |reports|
          iids = ci_report.requirements.keys
          break [] if iids.empty?

          build.project.requirements.opened.select(:id, :iid).where(iid: iids).each do |requirement|
            # ignore anything with any unexpected state
            new_state = ci_report.requirements[requirement.iid.to_s]
            next unless states.key?(new_state)

            reports << build_report(state: new_state, requirement: requirement, build: build, timestamp: timestamp)
          end
        end
      end

      def build_report(state:, requirement:, build:, timestamp:)
        new(
          requirement_id: requirement.id,
          # pipeline_reference will be removed:
          # https://gitlab.com/gitlab-org/gitlab/-/issues/219999
          pipeline_id: build.pipeline_id,
          build_id: build.id,
          author_id: build.user_id,
          created_at: timestamp,
          state: state
        )
      end
    end

    def validate_pipeline_reference
      if pipeline_id != build&.pipeline_id
        errors.add(:build, _('build pipeline reference mismatch'))
      end
    end
  end
end
