# frozen_string_literal: true

module Vulnerabilities
    class ConfirmService
      include Gitlab::Allowable
  
      def initialize(user, vulnerability)
        @user = user
        @vulnerability = vulnerability
      end
  
      def execute
        raise Gitlab::Access::AccessDeniedError unless can?(@user, :admin_vulnerability, @vulnerability.project)
  
        @vulnerability.tap do |vulnerability|
          vulnerability.update(state: :confirmed, confirmed_by: @user, resolved_at: Time.current)
        end
      end
    end
  end
  