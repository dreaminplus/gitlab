# frozen_string_literal: true

class ClusterSerializer < BaseSerializer
  include WithPagination
  entity ClusterEntity

  def represent_group(resource)
    represent(resource, {
      only: [
        :cluster_type,
        :enabled,
        :environment_scope,
        :name,
        :path,
        :status
      ]
    })
  end

  def represent_status(resource)
    represent(resource, { only: [:status, :status_reason, :applications] })
  end
end
