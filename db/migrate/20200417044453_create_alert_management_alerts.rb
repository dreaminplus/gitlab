class CreateAlertManagementAlerts < ActiveRecord::Migration[6.0]
  def change
    create_table :alert_management_alerts do |t|
      t.text :title, null: false, limit: 200
      t.text :description, limit: 1000
      t.text :service, limit: 100
      t.text :monitoring_tool, limit: 100
      t.text :host, limit: 100
      t.text :fingerprint, limit: 40

      t.integer :severity, default: 0, null: false
      t.integer :status, default: 0, null: false

      t.jsonb :payload
      t.integer :events, default: 1, null: false
      t.datetime :started_at
      t.datetime :ended_at

      t.references :issue, foreign_key: true
      t.references :project, null: false, foreign_key: { on_delete: :cascade }
      t.index :title
      t.index :events
      t.index :started_at
      t.index :ended_at
      t.index :severity
      t.index :status
      t.index :fingerprint

      t.timestamps
    end
  end
end
