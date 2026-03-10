# frozen_string_literal: true

class CreateBookings < ActiveRecord::Migration[7.2]
  def change
    create_table :bookings do |t|
      t.references :onboarding_session, null: false, foreign_key: true
      t.datetime :starts_at, null: false
      t.integer :duration_minutes, default: 30
      t.string :service_type
      t.string :status, default: "confirmed"
      t.timestamps
    end
  end
end
