# frozen_string_literal: true

class CreateMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :messages do |t|
      t.references :onboarding_session, null: false, foreign_key: true
      t.string :role, null: false
      t.text :content
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :messages, [:onboarding_session_id, :created_at]
  end
end
