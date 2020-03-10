class AddIndexOnUserIdAndCreatedAtToCiPipelines < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_pipelines, [:user_id, :created_at]
  end

  def down
    remove_concurrent_index :ci_pipelines, [:author_id, :created_at]
  end
end
