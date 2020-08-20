# frozen_string_literal: true

require 'securerandom'

module Geo
  # This class is similar to RepositoryBaseSyncService
  # but it works in a scope of Self-Service-Framework
  class RepositoryBaseSsfSyncService
    include ExclusiveLeaseGuard
    include ::Gitlab::ShellAdapter
    include ::Gitlab::Geo::LogHelpers
    include Delay

    class << self
      attr_accessor :type
    end

    attr_reader :replicator, :registry

    GEO_REMOTE_NAME  = 'geo'
    LEASE_TIMEOUT    = 8.hours
    LEASE_KEY_PREFIX = 'geo_sync_ssf_service'
    RETRIES_BEFORE_REDOWNLOAD = 5

    def initialize(replicator)
      @replicator = replicator
      @registry = registry
    end

    def execute
      try_obtain_lease do
        log_info("Started #{type} sync")

        sync_repository

        log_info("Finished #{type} sync")
      end
    end

    def sync_repository
      start_registry_sync!
      fetch_repository
      mark_sync_as_successful
    rescue Gitlab::Shell::Error, Gitlab::Git::BaseError => e
      # In some cases repository does not exist, the only way to know about this is to parse the error text.
      # If it does not exist we should consider it as successfully downloaded.
      if e.message.include? Gitlab::GitAccess::ERROR_MESSAGES[:no_repo]
        log_info('Repository is not found, marking it as successfully synced')
        mark_sync_as_successful(missing_on_primary: true)
      else
        fail_registry_sync!('Error syncing design repository', e)
      end
    rescue Gitlab::Git::Repository::NoRepository => e
      log_info('Marking the design repository for a forced re-download')
      fail_registry_sync!('Invalid design repository', e, force_to_redownload: true)
    ensure
      expire_repository_caches
    end

    def lease_key
      @lease_key ||= "#{LEASE_KEY_PREFIX}:#{type}:#{project.id}"
    end

    def lease_timeout
      LEASE_TIMEOUT
    end

    private

    def fetch_repository
      log_info("Trying to fetch #{type}")
      clean_up_temporary_repository

      if should_be_redownloaded?
        redownload_repository
        @new_repository = true
      elsif repository.exists?
        fetch_geo_mirror(repository)
      else
        ensure_repository
        fetch_geo_mirror(repository)
        @new_repository = true
      end
    end

    def redownload?
      registry.should_be_redownloaded?(type)
    end

    def redownload_repository
      log_info("Redownloading #{type}")

      if fetch_snapshot_into_temp_repo
        set_temp_repository_as_main

        return
      end

      log_info("Attempting to fetch repository via git")

      # `git fetch` needs an empty bare repository to fetch into
      temp_repo.create_repository
      fetch_geo_mirror(temp_repo)

      set_temp_repository_as_main
    ensure
      clean_up_temporary_repository
    end

    def current_node
      ::Gitlab::Geo.current_node
    end

    def fetch_geo_mirror(repository)
      # Fetch the repository, using a JWT header for authentication
      repository.with_config(jwt_authentication_header) do
        repository.fetch_as_mirror(remote_url, remote_name: GEO_REMOTE_NAME, forced: true)
      end
    end

    # Build a JWT header for authentication
    def jwt_authentication_header
      authorization = ::Gitlab::Geo::RepoSyncRequest.new(
        scope: repository.full_path
      ).authorization

      { "http.#{remote_url}.extraHeader" => "Authorization: #{authorization}" }
    end

    def remote_url
      Gitlab::Utils.append_path(Gitlab::Geo.primary_node.internal_url, "#{repository.full_path}.git")
    end

    # Use snapshotting for redownloads *only* when enabled.
    #
    # If writes happen to the repository while snapshotting, it may be
    # returned in an inconsistent state. However, a subsequent git fetch
    # will be enqueued by the log cursor, which should resolve any problems
    # it is possible to fix.
    def fetch_snapshot_into_temp_repo
      # Snapshots will miss the data that are shared in object pools, and snapshotting should
      # be avoided to guard against data loss.
      return if project.pool_repository

      log_info("Attempting to fetch repository via snapshot")

      temp_repo.create_from_snapshot(
        ::Gitlab::Geo.primary_node.snapshot_url(temp_repo),
        ::Gitlab::Geo::RepoSyncRequest.new(scope: ::Gitlab::Geo::API_SCOPE).authorization
      )
    rescue => err
      log_error('Snapshot attempt failed', err)
      false
    end

    def mark_sync_as_successful(missing_on_primary: false)
      log_info("Marking #{type} sync as successful")

      persisted = registry.finish_sync!(type, missing_on_primary)

      reschedule_sync unless persisted

      log_info("Finished #{type} sync",
              update_delay_s: update_delay_in_seconds,
              download_time_s: download_time_in_seconds)
    end

    def reschedule_sync
      log_info("Reschedule #{type} sync because a RepositoryUpdateEvent was processed during the sync")

      ::Geo::ProjectSyncWorker.perform_async(
        project.id,
        sync_repository: type.repository?,
        sync_wiki: type.wiki?
      )
    end

    def start_registry_sync!
      log_info("Marking #{type} sync as started")
      registry.start_sync!(type)
    end

    def fail_registry_sync!(message, error, attrs = {})
      log_error(message, error)

      registry.fail_sync!(type, message, error, attrs)

      repository.clean_stale_repository_files
    end

    def type
      @type ||= self.class.type.to_s.inquiry
    end

    def update_delay_in_seconds
      # We don't track the last update time of repositories and Wiki
      # separately in the main database
      return unless project.last_repository_updated_at

      (last_successful_sync_at.to_f - project.last_repository_updated_at.to_f).round(3)
    end

    def download_time_in_seconds
      (Time.current.to_f - registry.last_synced_at.to_f).round(3)
    end

    def last_successful_sync_at
      registry.public_send("last_#{type}_successful_sync_at") # rubocop:disable GitlabSecurity/PublicSend
    end

    def last_synced_at
      registry.public_send("last_#{type}_synced_at") # rubocop:disable GitlabSecurity/PublicSend
    end

    def disk_path_temp
      # We use "@" as it's not allowed to use it in a group or project name
      @disk_path_temp ||= "@geo-temporary/#{repository.disk_path}"
    end

    def deleted_disk_path_temp
      @deleted_path ||= "@failed-geo-sync/#{repository.disk_path}"
    end

    def temp_repo
      @temp_repo ||= ::Repository.new(repository.full_path, repository.container, shard: repository.shard, disk_path: disk_path_temp, repo_type: repository.repo_type)
    end

    def clean_up_temporary_repository
      exists = gitlab_shell.repository_exists?(project.repository_storage, disk_path_temp + '.git')

      if exists && !gitlab_shell.remove_repository(project.repository_storage, disk_path_temp)
        raise Gitlab::Shell::Error, "Temporary #{type} can not be removed"
      end
    end

    def set_temp_repository_as_main
      log_info(
        "Setting newly downloaded repository as main",
        storage_shard: project.repository_storage,
        temp_path: disk_path_temp,
        deleted_disk_path_temp: deleted_disk_path_temp,
        disk_path: repository.disk_path
      )

      # Remove the deleted path in case it exists, but it may not be there
      gitlab_shell.remove_repository(project.repository_storage, deleted_disk_path_temp)

      # Make sure we have the most current state of exists?
      repository.expire_exists_cache

      # Move the current canonical repository to the deleted path for reference
      if repository.exists?
        unless gitlab_shell.mv_repository(project.repository_storage, repository.disk_path, deleted_disk_path_temp)
          raise Gitlab::Shell::Error, 'Can not move original repository out of the way'
        end
      end

      # Move the temporary repository to the canonical path

      unless gitlab_shell.mv_repository(project.repository_storage, disk_path_temp, repository.disk_path)
        raise Gitlab::Shell::Error, 'Can not move temporary repository to canonical location'
      end

      # Purge the original repository
      unless gitlab_shell.remove_repository(project.repository_storage, deleted_disk_path_temp)
        raise Gitlab::Shell::Error, 'Can not remove outdated main repository'
      end
    end

    def new_repository?
      @new_repository
    end

    def repository
      replicator.repository
    end

    def ensure_repository
      repository.create_if_not_exists
    end

    def expire_repository_caches
      log_info('Expiring caches for repository')
      repository.after_sync
    end

    def should_be_redownloaded?
      return true if registry.force_to_redownload # rubocop:disable GitlabSecurity/PublicSend

      registry.retry_count > RETRIES_BEFORE_REDOWNLOAD
    end

    def reschedule_sync
      log_info("Reschedule design sync because a RepositoryUpdateEvent was processed during the sync")

      replicator.reschedule_sync
    end
  end
end
