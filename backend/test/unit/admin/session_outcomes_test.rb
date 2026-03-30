# frozen_string_literal: true

require "test_helper"

module Admin
  class SessionOutcomesTest < ActiveSupport::TestCase
    include ActiveSupport::Testing::TimeHelpers

    test "marks abandoned when inactive over 24h" do
      travel_to Time.zone.parse("2026-03-30 12:00:00") do
        s = OnboardingSession.create!(
          current_step: "welcome",
          status: "active",
          last_interaction_at: 25.hours.ago,
          updated_at: 25.hours.ago
        )
        row = SessionOutcomes.build_row(s)
        assert_equal "abandoned", row[:outcome]
      end
    end

    test "marks active when recently updated" do
      s = OnboardingSession.create!(current_step: "welcome", status: "active", last_interaction_at: 1.hour.ago)
      row = SessionOutcomes.build_row(s)
      assert_equal "active", row[:outcome]
    end

    test "marks completed" do
      s = OnboardingSession.create!(current_step: "complete", status: "active")
      row = SessionOutcomes.build_row(s)
      assert_equal "completed", row[:outcome]
    end

    test "filters by status" do
      OnboardingSession.create!(current_step: "complete", status: "active")
      rows = SessionOutcomes.call(status: "completed")
      assert_operator rows.size, :>=, 1
      assert(rows.all? { |r| r[:outcome] == "completed" })
    end
  end
end
