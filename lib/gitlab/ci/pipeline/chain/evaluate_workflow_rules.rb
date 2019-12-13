# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class EvaluateWorkflowRules < Chain::Base
          include ::Gitlab::Utils::StrongMemoize
          include Chain::Helpers

          def perform!
            return unless feature_enabled?

            unless workflow_passed?
              error('Pipeline filtered out by workflow rules.')
            end
          end

          def break?
            return false unless feature_enabled?

            !workflow_passed?
          end

          private

          def feature_enabled?
            Feature.enabled?(:workflow_rules, default_enabled: true)
          end

          def workflow_passed?
            strong_memoize(:workflow_passed) do
              workflow_rules.evaluate(@pipeline, global_context).pass?
            end
          end

          def workflow_rules
            Gitlab::Ci::Build::Rules.new(
              workflow_config[:rules], default_when: 'always')
          end

          def global_context
            Gitlab::Ci::Build::Context::Global.new(
              @pipeline, yaml_variables: workflow_config[:yaml_variables])
          end

          def workflow_config
            @command.config_processor.workflow_attributes || {}
          end
        end
      end
    end
  end
end
