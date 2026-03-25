# frozen_string_literal: true

require "test_helper"

module Scheduling
  class ReschedulingServiceTest < ActiveSupport::TestCase
    def setup
      @session = OnboardingSession.create!(status: "active", current_step: "scheduling")
      @slot = AppointmentSlot.create!(date: Date.tomorrow, start_time: "10:00", end_time: "10:30", service_type: "orientation", capacity: 5, booked_count: 1)
      @booking = Booking.create!(
        onboarding_session: @session,
        appointment_slot: @slot,
        starts_at: DateTime.new(Date.tomorrow.year, Date.tomorrow.month, Date.tomorrow.day, 10, 0),
        duration_minutes: 30,
        service_type: "orientation",
        status: "confirmed"
      )
      @new_slot = AppointmentSlot.create!(date: Date.tomorrow + 1, start_time: "14:00", end_time: "14:30", service_type: "orientation", capacity: 5)
    end

    test "cancels a booking and decrements slot count" do
      Scheduling::ReschedulingService.cancel!(@booking)
      assert_equal "cancelled", @booking.reload.status
      assert_equal 0, @slot.reload.booked_count
    end

    test "reschedules: cancels old booking and creates new one" do
      new_booking = Scheduling::ReschedulingService.reschedule!(@booking, @new_slot.id)

      assert_equal "cancelled", @booking.reload.status
      assert_equal 0, @slot.reload.booked_count
      assert new_booking.persisted?
      assert_equal @new_slot.id, new_booking.appointment_slot_id
      assert_equal "confirmed", new_booking.status
      assert_equal 1, @new_slot.reload.booked_count
    end

    test "rejects cancellation within cancellation window" do
      soon_slot = AppointmentSlot.create!(date: Date.current, start_time: 1.hour.from_now.strftime("%H:%M"), end_time: 2.hours.from_now.strftime("%H:%M"), service_type: "orientation", capacity: 5, booked_count: 1)
      soon_booking = Booking.create!(
        onboarding_session: @session,
        appointment_slot: soon_slot,
        starts_at: 1.hour.from_now,
        duration_minutes: 30,
        service_type: "orientation",
        status: "confirmed"
      )

      assert_raises(Scheduling::ReschedulingService::TooLateError) do
        Scheduling::ReschedulingService.cancel!(soon_booking)
      end
    end

    test "lists bookings for a session" do
      bookings = Scheduling::ReschedulingService.bookings_for(@session)
      assert_equal 1, bookings.size
      assert_equal @booking.id, bookings.first.id
    end

    test "cancel already-cancelled booking is no-op" do
      @booking.update!(status: "cancelled")
      assert_nothing_raised { Scheduling::ReschedulingService.cancel!(@booking) }
    end
  end
end
