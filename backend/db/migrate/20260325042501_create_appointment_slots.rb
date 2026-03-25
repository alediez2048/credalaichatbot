class CreateAppointmentSlots < ActiveRecord::Migration[7.2]
  def change
    create_table :appointment_slots do |t|
      t.date :date, null: false
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.integer :duration_minutes, default: 30
      t.string :service_type, null: false
      t.integer :capacity, default: 1, null: false
      t.integer :booked_count, default: 0, null: false
      t.string :status, default: "available", null: false
      t.bigint :created_by
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :appointment_slots, [:date, :service_type]
    add_index :appointment_slots, :status

    add_reference :bookings, :appointment_slot, foreign_key: true, null: true
  end
end
