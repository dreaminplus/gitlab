# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddSprintIdIndexToIssues < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :issues, :sprints, column: :sprint_id
    add_concurrent_index :issues, :sprint_id
  end

  def down
    remove_concurrent_index :issues, :sprint_id
    remove_foreign_key :issues, column: :sprint_id
  end
end
