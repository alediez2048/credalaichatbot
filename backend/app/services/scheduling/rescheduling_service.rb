# frozen_string_literal: true

module Scheduling
  class ReschedulingService
    class TooLateError < StandardError; end

    CANCELLATION_WINDOW_HOURS = 2

    class << self
      # Cancel a booking, decrement the slot's booked_count
      def cancel!(booking)
        return if booking.status == "cancelled"

        if too_late_to_cancel?(booking)
          raise TooLateError, "Cannot cancel within #{CANCELLATION_WINDOW_HOURS} hours of the appointment"
        end

        ActiveRecord::Base.transaction do
          booking.update!(status: "cancelled")
          if booking.appointment_slot
            slot = AppointmentSlot.lock.find(booking.appointment_slot_id)
            slot.decrement!(:booked_count) if slot.booked_count > 0
          end
        end
      end

      # Cancel old booking and book a new slot
      def reschedule!(booking, new_slot_id)
        cancel!(booking)
        SlotManager.book!(new_slot_id, booking.onboarding_session_id)
      end

      # List active bookings for a session
      def bookings_for(session)
        session.bookings.where.not(status: "cancelled").order(:starts_at)
      end

      private

      def too_late_to_cancel?(booking)
        return false unless booking.starts_at
        booking.starts_at <= CANCELLATION_WINDOW_HOURS.hours.from_now
      end
    end
  end
end
