# frozen_string_literal: true

module EE
  module WikiPages
    # BaseService EE mixin
    #
    # This module is intended to encapsulate EE-specific service logic
    # and be included in the `WikiPages::BaseService` service
    module BaseService
      extend ActiveSupport::Concern

      private

      def execute_hooks(page)
        super
        process_wiki_repository_update
      end

      def process_wiki_repository_update
        if ::Gitlab::Geo.primary?
          ::Geo::RepositoryUpdatedService.new(container.wiki.repository).execute
        end
      end
    end
  end
end
