# frozen_string_literal: true

class AddCostFactorFiledsToCiRunners < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:ci_runners, :public_projects_minutes_cost_factor, :float, default: 0.0)
    add_column_with_default(:ci_runners, :private_projects_minutes_cost_factor, :float, default: 1.0)
  end

  def down
    remove_column(:ci_runners, :public_projects_minutes_cost_factor)
    remove_column(:ci_runners, :private_projects_minutes_cost_factor)
  end
end
