# frozen_string_literal: true

require "test_helper"

module Onboarding
  class MilestoneTrackerTest < ActiveSupport::TestCase
    def setup
      @session = OnboardingSession.create!(status: "active", current_step: "welcome", progress_percent: 0)
    end

    test "detects 25% milestone" do
      @session.update!(progress_percent: 20)
      assert_not Onboarding::MilestoneTracker.milestone_reached?(@session, 25)

      @session.update!(progress_percent: 25)
      assert Onboarding::MilestoneTracker.milestone_reached?(@session, 25)
    end

    test "returns encouragement message for milestone" do
      msg = Onboarding::MilestoneTracker.encouragement_for(25)
      assert msg.present?
      assert_includes msg.downcase, "quarter"
    end

    test "returns completion celebration for 100%" do
      msg = Onboarding::MilestoneTracker.encouragement_for(100)
      assert msg.present?
      assert_includes msg.downcase, "complete"
    end

    test "check_milestones returns newly crossed milestones" do
      @session.update!(progress_percent: 50, metadata: { "_milestones_seen" => [25] })
      milestones = Onboarding::MilestoneTracker.check_milestones(@session)
      assert_includes milestones, 50
      assert_not_includes milestones, 25 # already seen
    end

    test "marks milestones as seen" do
      @session.update!(progress_percent: 75)
      Onboarding::MilestoneTracker.mark_seen!(@session, [25, 50, 75])
      seen = @session.reload.metadata["_milestones_seen"]
      assert_includes seen, 75
    end
  end
end
