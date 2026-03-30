# frozen_string_literal: true

class AddSmsFieldsAndEvents < ActiveRecord::Migration[7.2]
  def change
    change_table :onboarding_sessions, bulk: true do |t|
      t.string :phone_number
      t.boolean :sms_opt_in, default: false, null: false
      t.string :last_channel, default: "web", null: false
      t.datetime :last_interaction_at
      t.string :sms_thread_id
    end

    add_index :onboarding_sessions, :phone_number
    add_index :onboarding_sessions, :sms_opt_in
    add_index :onboarding_sessions, [:phone_number, :sms_opt_in]

    create_table :sms_events do |t|
      t.references :onboarding_session, null: true, foreign_key: true
      t.string :provider, null: false
      t.string :direction, null: false
      t.string :external_id
      t.string :phone_number
      t.text :body
      t.string :status, null: false, default: "received"
      t.text :error_message
      t.jsonb :metadata, default: {}, null: false
      t.timestamps
    end

    add_index :sms_events, [:provider, :direction, :external_id], unique: true, where: "external_id IS NOT NULL", name: "idx_sms_events_provider_direction_external_id"
    add_index :sms_events, [:phone_number, :created_at]
  end
end
