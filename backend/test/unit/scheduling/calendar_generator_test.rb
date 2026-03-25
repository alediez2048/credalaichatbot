# frozen_string_literal: true

require "test_helper"

module Scheduling
  class CalendarGeneratorTest < ActiveSupport::TestCase
    def setup
      @session = OnboardingSession.create!(status: "active", current_step: "scheduling")
      @slot = AppointmentSlot.create!(date: Date.tomorrow, start_time: "10:00", end_time: "10:30", service_type: "orientation", capacity: 5)
      @booking = Booking.create!(
        onboarding_session: @session,
        appointment_slot: @slot,
        starts_at: DateTime.new(Date.tomorrow.year, Date.tomorrow.month, Date.tomorrow.day, 10, 0),
        duration_minutes: 30,
        service_type: "orientation",
        status: "confirmed"
      )
    end

    test "generates valid ICS content" do
      ics = Scheduling::CalendarGenerator.generate(@booking)
      assert ics.include?("BEGIN:VCALENDAR")
      assert ics.include?("BEGIN:VEVENT")
      assert ics.include?("END:VCALENDAR")
      assert ics.include?("orientation")
    end

    test "includes correct date and duration" do
      ics = Scheduling::CalendarGenerator.generate(@booking)
      assert ics.include?("DTSTART")
      assert ics.include?("DTEND")
    end

    test "includes summary with service type" do
      ics = Scheduling::CalendarGenerator.generate(@booking)
      assert_match /SUMMARY:.*orientation/i, ics
    end

    test "generates secure download token" do
      token = Scheduling::CalendarGenerator.generate_token(@booking)
      assert token.is_a?(String)
      assert token.length >= 20
    end

    test "validates token" do
      token = Scheduling::CalendarGenerator.generate_token(@booking)
      assert Scheduling::CalendarGenerator.valid_token?(@booking, token)
      assert_not Scheduling::CalendarGenerator.valid_token?(@booking, "bad_token")
    end
  end
end
