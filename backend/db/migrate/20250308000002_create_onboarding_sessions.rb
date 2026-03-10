# frozen_string_literal: true

class CreateOnboardingSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :onboarding_sessions do |t|
      t.references :user, null: true, foreign_key: true
      t.string :anonymous_token
      t.string :current_step
      t.integer :progress_percent, default: 0
      t.string :status, default: "active"
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :onboarding_sessions, :anonymous_token, unique: true, where: "anonymous_token IS NOT NULL"
  end
end
