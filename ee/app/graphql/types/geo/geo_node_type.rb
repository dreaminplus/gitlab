# frozen_string_literal: true

module Types
  module Geo
    class GeoNodeType < BaseObject
      graphql_name 'GeoNode'

      authorize :read_geo_node

      field :id, GraphQL::ID_TYPE, null: false, description: 'ID of this GeoNode'
      field :primary, GraphQL::BOOLEAN_TYPE, null: true, description: 'Indicates whether this Geo node is the primary'
      field :enabled, GraphQL::BOOLEAN_TYPE, null: true, description: 'Indicates whether this Geo node is enabled'
      field :name, GraphQL::STRING_TYPE, null: true, description: 'The unique identifier for this Geo node'
      field :url, GraphQL::STRING_TYPE, null: true, description: 'The user-facing URL for this Geo node'
      field :internal_url, GraphQL::STRING_TYPE, null: true, description: 'The URL defined on the primary node that secondary nodes should use to contact it'
      field :files_max_capacity, GraphQL::INT_TYPE, null: true, description: 'The maximum concurrency of LFS/attachment backfill for this secondary node'
      field :repos_max_capacity, GraphQL::INT_TYPE, null: true, description: 'The maximum concurrency of repository backfill for this secondary node'
      field :verification_max_capacity, GraphQL::INT_TYPE, null: true, description: 'The maximum concurrency of repository verification for this secondary node'
      field :container_repositories_max_capacity, GraphQL::INT_TYPE, null: true, description: 'The maximum concurrency of container repository sync for this secondary node'
      field :sync_object_storage, GraphQL::BOOLEAN_TYPE, null: true, description: 'Indicates if this secondary node will replicate blobs in Object Storage'
      field :selective_sync_type, GraphQL::STRING_TYPE, null: true, description: 'Indicates if syncing is limited to only specific groups, or shards'
      field :selective_sync_shards, type: [GraphQL::STRING_TYPE], null: true, description: 'The repository storages whose projects should be synced, if `selective_sync_type` == `shards`'
      field :selective_sync_namespaces, ::Types::NamespaceType.connection_type, null: true, method: :namespaces, description: 'The namespaces that should be synced, if `selective_sync_type` == `namespaces`'
      field :minimum_reverification_interval, GraphQL::INT_TYPE, null: true, description: 'The interval (in days) in which the repository verification is valid. Once expired, it will be reverified'
    end
  end
end
