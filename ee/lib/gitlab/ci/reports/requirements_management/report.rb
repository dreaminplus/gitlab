# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module RequirementsManagement
        class Report
          attr_reader :requirements

          def initialize
            @requirements = {}
          end

          def add_requirement(key, value)
            @requirements[key.remove('requirement_iid')] = value
          end

          def all_passed?
            @requirements.values.uniq == 'passed'
          end
        end
      end
    end
  end
end
