# frozen_string_literal: true

module Elastic
  module SnippetsSearch
    extend ActiveSupport::Concern

    include ApplicationVersionedSearch

    def use_elasticsearch?
      # FIXME: check project.use_elasticsearch? for ProjectSnippets?
      # see https://gitlab.com/gitlab-org/gitlab/issues/11850
      ::Gitlab::CurrentSettings.elasticsearch_indexing?
    end

    included do
      class << self
        delegate :elastic_search_code, to: :__elasticsearch__
      end
    end
  end
end
