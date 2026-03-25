# frozen_string_literal: true

module Scheduling
  class SlotManager
    class SlotFullError < StandardError; end
    class SlotNotFoundError < StandardError; end

    class << self
      def create_slot(date:, start_time:, end_time:, service_type:, capacity: 1, created_by: nil)
        AppointmentSlot.create!(
          date: date,
          start_time: start_time,
          end_time: end_time,
          service_type: service_type,
          capacity: capacity,
          created_by: created_by
        )
      end

      def list_available(service_type: nil, date_from: nil, date_to: nil)
        AppointmentSlot
          .available
          .future
          .for_service(service_type)
          .in_date_range(date_from, date_to)
          .order(:date, :start_time)
      end

      def book!(slot_id, onboarding_session_id)
        slot = AppointmentSlot.lock.find_by(id: slot_id)
        raise SlotNotFoundError, "Slot not found" unless slot
        raise SlotFullError, "This time slot is fully booked" if slot.full?

        ActiveRecord::Base.transaction do
          slot.increment!(:booked_count)
          Booking.create!(
            onboarding_session_id: onboarding_session_id,
            appointment_slot_id: slot.id,
            starts_at: DateTime.new(slot.date.year, slot.date.month, slot.date.day, slot.start_time.hour, slot.start_time.min),
            duration_minutes: slot.duration_minutes,
            service_type: slot.service_type,
            status: "confirmed"
          )
        end
      end

      def cancel_slot(slot_id)
        slot = AppointmentSlot.find_by(id: slot_id)
        raise SlotNotFoundError, "Slot not found" unless slot
        slot.update!(status: "cancelled")
      end

      def update_slot(slot_id, **attrs)
        slot = AppointmentSlot.find_by(id: slot_id)
        raise SlotNotFoundError, "Slot not found" unless slot
        slot.update!(**attrs)
        slot
      end
    end
  end
end
