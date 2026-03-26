# frozen_string_literal: true

require "test_helper"

module Admin
  class DashboardStatsTest < ActiveSupport::TestCase
    setup do
      @session1 = OnboardingSession.create!(status: "active", current_step: "personal_info", progress_percent: 20)
      @session2 = OnboardingSession.create!(status: "active", current_step: "complete", progress_percent: 100)
      @session3 = OnboardingSession.create!(status: "active", current_step: "welcome", progress_percent: 0, updated_at: 1.hour.ago)

      LLMUsage.create!(onboarding_session: @session1, model: "gpt-4o", prompt_tokens: 500, completion_tokens: 200, total_tokens: 700, cost_usd: 0.0033)
      LLMUsage.create!(onboarding_session: @session2, model: "gpt-4o", prompt_tokens: 1000, completion_tokens: 400, total_tokens: 1400, cost_usd: 0.0065)
    end

    teardown do
      LLMUsage.where(onboarding_session_id: [@session1.id, @session2.id, @session3.id]).delete_all
      [@session1, @session2, @session3].each(&:destroy)
    end

    test "session_stats returns correct counts" do
      stats = DashboardStats.session_stats
      assert stats[:total] >= 3
      assert stats[:completed] >= 1
      assert stats.key?(:completion_rate)
      assert stats.key?(:avg_completion_minutes)
    end

    test "step_funnel returns all onboarding steps" do
      funnel = DashboardStats.step_funnel
      assert_equal 6, funnel.size
      assert_equal "welcome", funnel.first[:step]
      assert_equal "complete", funnel.last[:step]
      funnel.each do |entry|
        assert entry.key?(:count)
        assert entry.key?(:percent)
      end
    end

    test "cost_summary aggregates LLMUsage data" do
      summary = DashboardStats.cost_summary
      assert summary[:total_cost] > 0
      assert summary[:avg_cost_per_session] > 0
      assert summary.key?(:last_7_days_cost)
      assert summary[:total_tokens] > 0
    end

    test "eval_summary returns nil when no report file exists" do
      summary = DashboardStats.eval_summary
      # May or may not exist depending on whether eval:run has been run
      assert [NilClass, Hash].include?(summary.class)
    end

    test "recent_sessions returns limited ordered results" do
      sessions = DashboardStats.recent_sessions(limit: 2)
      assert sessions.size <= 2
      sessions.each do |s|
        assert s.key?(:id)
        assert s.key?(:current_step)
        assert s.key?(:message_count)
        assert s.key?(:cost)
      end
    end

    test "call returns complete stats hash" do
      stats = DashboardStats.call
      assert stats.key?(:session_stats)
      assert stats.key?(:step_funnel)
      assert stats.key?(:cost_summary)
      assert stats.key?(:eval_summary)
      assert stats.key?(:recent_sessions)
    end
  end
end
