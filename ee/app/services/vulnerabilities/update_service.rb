# frozen_string_literal: true

module Vulnerabilities
  class UpdateService
    include Gitlab::Allowable

    attr_reader :project, :author, :finding

    def initialize(project, author, finding:)
      @project = project
      @author = author
      @finding = finding
    end

    def execute(vulnerability)
      raise Gitlab::Access::AccessDeniedError unless can?(author, :create_vulnerability, project)

      vulnerability.update(vulnerability_params(vulnerability))

      vulnerability
    end

    private

    def vulnerability_params(vulnerability)
      {
        title: finding.name,
        severity: vulnerability.severity_overridden? ? vulnerability.severity : finding.severity,
        confidence: vulnerability.confidence_overridden? ? vulnerability.confidence : finding.confidence
      }
    end
  end
end
