# frozen_string_literal: true

class AddEncryptedRunnersTokenToProjects < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # rubocop:disable Migration/AddColumnsToWideTables
  # rubocop:disable Migration/AddLimitToStringColumns
  def change
    add_column :projects, :runners_token_encrypted, :string
  end
  # rubocop:enable Migration/AddColumnsToWideTables
  # rubocop:enable Migration/AddLimitToStringColumns
end
