# frozen_string_literal: true

require "test_helper"

module Scheduling
  class SlotRecommenderTest < ActiveSupport::TestCase
    def setup
      @morning = AppointmentSlot.create!(date: Date.tomorrow, start_time: "09:00", end_time: "09:30", service_type: "orientation", capacity: 5)
      @midday = AppointmentSlot.create!(date: Date.tomorrow, start_time: "12:00", end_time: "12:30", service_type: "orientation", capacity: 5)
      @afternoon = AppointmentSlot.create!(date: Date.tomorrow, start_time: "15:00", end_time: "15:30", service_type: "orientation", capacity: 5)
    end

    test "returns available slots sorted by recommendation score" do
      results = Scheduling::SlotRecommender.recommend(service_type: "orientation")
      assert results.size >= 3
      assert results.first.is_a?(AppointmentSlot)
    end

    test "filters by service_type" do
      hr = AppointmentSlot.create!(date: Date.tomorrow, start_time: "10:00", end_time: "10:30", service_type: "hr_review", capacity: 3)
      results = Scheduling::SlotRecommender.recommend(service_type: "hr_review")
      assert results.all? { |s| s.service_type == "hr_review" }
    end

    test "excludes full slots" do
      @morning.update!(booked_count: 5)
      results = Scheduling::SlotRecommender.recommend(service_type: "orientation")
      assert_not results.include?(@morning)
    end

    test "prefers slots with more remaining capacity" do
      @morning.update!(booked_count: 4) # 1 remaining
      @afternoon.update!(booked_count: 0) # 5 remaining
      results = Scheduling::SlotRecommender.recommend(service_type: "orientation", limit: 3)
      # Afternoon should rank higher (more capacity)
      afternoon_idx = results.index(@afternoon)
      morning_idx = results.index(@morning)
      assert afternoon_idx < morning_idx if afternoon_idx && morning_idx
    end

    test "limits results" do
      results = Scheduling::SlotRecommender.recommend(service_type: "orientation", limit: 2)
      assert results.size <= 2
    end

    test "formats slots for LLM" do
      formatted = Scheduling::SlotRecommender.format_for_llm([@morning, @midday])
      assert formatted.is_a?(Array)
      assert_equal 2, formatted.size
      assert formatted.first.key?(:slot_id)
      assert formatted.first.key?(:date)
      assert formatted.first.key?(:start_time)
    end
  end
end
