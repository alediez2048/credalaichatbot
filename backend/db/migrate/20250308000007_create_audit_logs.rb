# frozen_string_literal: true

class CreateAuditLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :audit_logs do |t|
      t.references :user, null: true, foreign_key: true
      t.references :onboarding_session, null: true, foreign_key: true
      t.string :action, null: false
      t.string :resource_type
      t.string :resource_id
      t.jsonb :payload, default: {}
      t.string :trace_id
      t.timestamps
    end

    add_index :audit_logs, :trace_id
    add_index :audit_logs, [:resource_type, :resource_id]
  end
end
