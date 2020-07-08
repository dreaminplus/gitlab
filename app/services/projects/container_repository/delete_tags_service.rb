# frozen_string_literal: true

module Projects
  module ContainerRepository
    class DeleteTagsService < BaseService
      def execute(container_repository)
        return error('access denied') unless can?(current_user, :destroy_container_image, project)

        tag_names = params[:tags]
        return error('not tags specified') if tag_names.blank?

        smart_delete(container_repository, tag_names)
      rescue Timeout::Error => e
        Gitlab::ErrorTracking.track_exception(e, tags_count: tag_names&.size, container_repository_id: container_repository&.id)
        error('Timeout while deleting tags')
      end

      private

      # Delete tags by name with a single DELETE request. This is only supported
      # by the GitLab Container Registry fork. See
      # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/23325 for details.
      def fast_delete(container_repository, tag_names)
        deleted_tags = with_timeout_if_enabled do
          tag_names.select do |name|
            container_repository.delete_tag_by_name(name)
          end
        end

        deleted_tags.any? ? success(deleted: deleted_tags) : error('could not delete tags')
      end

      def with_timeout_if_enabled
        if throttling_enabled?
          Timeout.timeout(service_timeout) { yield }
        else
          yield
        end
      end

      def throttling_enabled?
        Feature.enabled?(:container_registry_expiration_policies_throttling)
      end

      def service_timeout
        ::Gitlab::CurrentSettings.current_application_settings.container_registry_delete_tags_service_timeout
      end

      # Replace a tag on the registry with a dummy tag.
      # This is a hack as the registry doesn't support deleting individual
      # tags. This code effectively pushes a dummy image and assigns the tag to it.
      # This way when the tag is deleted only the dummy image is affected.
      # This is used to preserve compatibility with third-party registries that
      # don't support fast delete.
      # See https://gitlab.com/gitlab-org/gitlab/issues/15737 for a discussion
      def slow_delete(container_repository, tag_names)
        # generates the blobs for the dummy image
        dummy_manifest = container_repository.client.generate_empty_manifest(container_repository.path)
        return error('could not generate manifest') if dummy_manifest.nil?

        deleted_tags = replace_tag_manifests(container_repository, dummy_manifest, tag_names)

        # Deletes the dummy image
        # All created tag digests are the same since they all have the same dummy image.
        # a single delete is sufficient to remove all tags with it
        if deleted_tags.any? && container_repository.delete_tag_by_digest(deleted_tags.each_value.first)
          success(deleted: deleted_tags.keys)
        else
          error('could not delete tags')
        end
      end

      def smart_delete(container_repository, tag_names)
        fast_delete_enabled = Feature.enabled?(:container_registry_fast_tag_delete, default_enabled: true)
        if fast_delete_enabled && container_repository.client.supports_tag_delete?
          fast_delete(container_repository, tag_names)
        else
          slow_delete(container_repository, tag_names)
        end
      end

      # update the manifests of the tags with the new dummy image
      def replace_tag_manifests(container_repository, dummy_manifest, tag_names)
        deleted_tags = {}

        tag_names.each do |name|
          digest = container_repository.client.put_tag(container_repository.path, name, dummy_manifest)
          next unless digest

          deleted_tags[name] = digest
        end

        # make sure the digests are the same (it should always be)
        digests = deleted_tags.values.uniq

        # rubocop: disable CodeReuse/ActiveRecord
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(ArgumentError.new('multiple tag digests')) if digests.many?

        deleted_tags
      end
    end
  end
end
