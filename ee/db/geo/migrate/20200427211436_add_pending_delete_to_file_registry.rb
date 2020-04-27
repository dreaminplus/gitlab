# frozen_string_literal: true

class AddPendingDeleteToFileRegistry < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:file_registry,
                            :pending_delete,
                            :boolean,
                            default: true,
                            allow_null: false)
  end

  def down
    remove_column(:file_registry, :pending_delete)
  end
end
