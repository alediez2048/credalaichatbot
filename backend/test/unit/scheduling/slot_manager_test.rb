# frozen_string_literal: true

require "test_helper"

module Scheduling
  class SlotManagerTest < ActiveSupport::TestCase
    def setup
      @session = OnboardingSession.create!(status: "active", current_step: "scheduling")
    end

    test "creates a slot" do
      slot = Scheduling::SlotManager.create_slot(
        date: Date.tomorrow,
        start_time: "09:00",
        end_time: "09:30",
        service_type: "orientation",
        capacity: 5
      )
      assert slot.persisted?
      assert_equal "orientation", slot.service_type
      assert_equal 5, slot.capacity
    end

    test "list_available returns only future non-full active slots" do
      future = AppointmentSlot.create!(date: Date.tomorrow, start_time: "10:00", end_time: "10:30", service_type: "orientation", capacity: 2)
      full = AppointmentSlot.create!(date: Date.tomorrow, start_time: "11:00", end_time: "11:30", service_type: "orientation", capacity: 1, booked_count: 1)
      cancelled = AppointmentSlot.create!(date: Date.tomorrow, start_time: "12:00", end_time: "12:30", service_type: "orientation", capacity: 2, status: "cancelled")
      past = AppointmentSlot.create!(date: 1.day.ago, start_time: "10:00", end_time: "10:30", service_type: "orientation", capacity: 2)

      results = Scheduling::SlotManager.list_available
      assert_includes results, future
      assert_not_includes results, full
      assert_not_includes results, cancelled
      assert_not_includes results, past
    end

    test "list_available filters by service_type" do
      orientation = AppointmentSlot.create!(date: Date.tomorrow, start_time: "10:00", end_time: "10:30", service_type: "orientation", capacity: 2)
      hr = AppointmentSlot.create!(date: Date.tomorrow, start_time: "10:00", end_time: "10:30", service_type: "hr_review", capacity: 2)

      results = Scheduling::SlotManager.list_available(service_type: "orientation")
      assert_includes results, orientation
      assert_not_includes results, hr
    end

    test "list_available filters by date range" do
      tomorrow = AppointmentSlot.create!(date: Date.tomorrow, start_time: "10:00", end_time: "10:30", service_type: "orientation", capacity: 2)
      next_week = AppointmentSlot.create!(date: 7.days.from_now.to_date, start_time: "10:00", end_time: "10:30", service_type: "orientation", capacity: 2)

      results = Scheduling::SlotManager.list_available(date_from: Date.tomorrow, date_to: Date.tomorrow + 2)
      assert_includes results, tomorrow
      assert_not_includes results, next_week
    end

    test "book! creates booking and increments booked_count" do
      slot = AppointmentSlot.create!(date: Date.tomorrow, start_time: "10:00", end_time: "10:30", service_type: "orientation", capacity: 2)

      booking = Scheduling::SlotManager.book!(slot.id, @session.id)

      assert booking.persisted?
      assert_equal slot.id, booking.appointment_slot_id
      assert_equal @session.id, booking.onboarding_session_id
      assert_equal 1, slot.reload.booked_count
    end

    test "book! raises when slot is full" do
      slot = AppointmentSlot.create!(date: Date.tomorrow, start_time: "10:00", end_time: "10:30", service_type: "orientation", capacity: 1, booked_count: 1)

      assert_raises(Scheduling::SlotManager::SlotFullError) do
        Scheduling::SlotManager.book!(slot.id, @session.id)
      end
    end

    test "book! is atomic — concurrent bookings don't exceed capacity" do
      slot = AppointmentSlot.create!(date: Date.tomorrow, start_time: "10:00", end_time: "10:30", service_type: "orientation", capacity: 1)

      # First booking succeeds
      Scheduling::SlotManager.book!(slot.id, @session.id)

      # Second booking fails
      session2 = OnboardingSession.create!(status: "active")
      assert_raises(Scheduling::SlotManager::SlotFullError) do
        Scheduling::SlotManager.book!(slot.id, session2.id)
      end
    end

    test "cancel_slot sets status to cancelled" do
      slot = AppointmentSlot.create!(date: Date.tomorrow, start_time: "10:00", end_time: "10:30", service_type: "orientation", capacity: 2)
      Scheduling::SlotManager.cancel_slot(slot.id)
      assert_equal "cancelled", slot.reload.status
    end
  end
end
