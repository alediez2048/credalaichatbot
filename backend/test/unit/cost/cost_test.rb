# frozen_string_literal: true

require "test_helper"

class CostCalculatorTest < ActiveSupport::TestCase
  test "calculates gpt-4o cost correctly" do
    # 1000 input tokens * 0.0025/1k = 0.0025
    # 500 output tokens * 0.01/1k = 0.005
    # Total = 0.0075
    cost = Cost::Calculator.calculate(model: "gpt-4o", prompt_tokens: 1000, completion_tokens: 500)
    assert_equal BigDecimal("0.0075"), cost
  end

  test "calculates gpt-4o-mini cost correctly" do
    # 2000 input * 0.00015/1k = 0.0003
    # 1000 output * 0.0006/1k = 0.0006
    # Total = 0.0009
    cost = Cost::Calculator.calculate(model: "gpt-4o-mini", prompt_tokens: 2000, completion_tokens: 1000)
    assert_equal BigDecimal("0.0009"), cost
  end

  test "returns zero for unknown model" do
    cost = Cost::Calculator.calculate(model: "unknown-model", prompt_tokens: 1000, completion_tokens: 500)
    assert_equal BigDecimal("0"), cost
  end

  test "handles zero tokens" do
    cost = Cost::Calculator.calculate(model: "gpt-4o", prompt_tokens: 0, completion_tokens: 0)
    assert_equal BigDecimal("0"), cost
  end
end

class CostTrackerTest < ActiveSupport::TestCase
  setup do
    @session = OnboardingSession.create!(status: "active", current_step: "welcome")
  end

  teardown do
    @session.destroy
  end

  test "creates LLMUsage record from usage hash" do
    assert_difference "LLMUsage.count", 1 do
      Cost::Tracker.record(
        session_id: @session.id,
        model: "gpt-4o",
        usage: { "prompt_tokens" => 500, "completion_tokens" => 200, "total_tokens" => 700 }
      )
    end

    record = LLMUsage.last
    assert_equal @session.id, record.onboarding_session_id
    assert_equal "gpt-4o", record.model
    assert_equal 500, record.prompt_tokens
    assert_equal 200, record.completion_tokens
    assert_equal 700, record.total_tokens
    assert record.cost_usd > 0
  end

  test "handles symbol keys in usage hash" do
    Cost::Tracker.record(
      session_id: @session.id,
      model: "gpt-4o",
      usage: { prompt_tokens: 100, completion_tokens: 50 }
    )
    assert_equal 1, LLMUsage.where(onboarding_session_id: @session.id).count
  end

  test "no-ops when session_id is nil" do
    assert_no_difference "LLMUsage.count" do
      Cost::Tracker.record(session_id: nil, model: "gpt-4o", usage: { "prompt_tokens" => 100 })
    end
  end

  test "no-ops when usage is nil" do
    assert_no_difference "LLMUsage.count" do
      Cost::Tracker.record(session_id: @session.id, model: "gpt-4o", usage: nil)
    end
  end
end

class CostProjectorTest < ActiveSupport::TestCase
  setup do
    @session1 = OnboardingSession.create!(status: "active", current_step: "welcome")
    @session2 = OnboardingSession.create!(status: "active", current_step: "welcome")

    # Session 1: $0.01 total
    LLMUsage.create!(onboarding_session: @session1, model: "gpt-4o", prompt_tokens: 1000, completion_tokens: 500, total_tokens: 1500, cost_usd: 0.0075)
    LLMUsage.create!(onboarding_session: @session1, model: "gpt-4o", prompt_tokens: 500, completion_tokens: 100, total_tokens: 600, cost_usd: 0.0025)

    # Session 2: $0.005
    LLMUsage.create!(onboarding_session: @session2, model: "gpt-4o", prompt_tokens: 1000, completion_tokens: 250, total_tokens: 1250, cost_usd: 0.005)
  end

  teardown do
    LLMUsage.where(onboarding_session_id: [@session1.id, @session2.id]).delete_all
    @session1.destroy
    @session2.destroy
  end

  test "projects monthly cost based on historical data" do
    projection = Cost::Projector.project(users_per_month: 1000)

    assert_equal 1000, projection[:users_per_month]
    assert_equal 1.2, projection[:avg_sessions_per_user]
    assert projection[:avg_cost_per_session] > 0
    assert projection[:projected_monthly_cost] > 0
    assert projection[:projected_annual_cost] > 0
    assert_equal (projection[:projected_monthly_cost] * 12).round(2), projection[:projected_annual_cost]
  end

  test "returns zero projection with no usage data" do
    LLMUsage.delete_all
    projection = Cost::Projector.project(users_per_month: 500)

    assert_equal 0.0, projection[:projected_monthly_cost]
    assert_equal 0.0, projection[:projected_annual_cost]
  end
end
