class CreateSentimentReadings < ActiveRecord::Migration[7.2]
  def change
    create_table :sentiment_readings do |t|
      t.references :onboarding_session, null: false, foreign_key: true
      t.string :label, null: false
      t.decimal :confidence, precision: 5, scale: 4
      t.jsonb :signals, default: []
      t.bigint :message_window_start_id
      t.bigint :message_window_end_id
      t.timestamps
    end

    add_index :sentiment_readings, [:onboarding_session_id, :created_at]
  end
end
