# frozen_string_literal: true

module Cost
  class Projector
    AVG_SESSIONS_PER_USER = 1.2

    # Project monthly cost at a given user volume based on historical usage data.
    # @param users_per_month [Integer]
    # @return [Hash] projection breakdown
    def self.project(users_per_month:)
      session_costs = LLMUsage.group(:onboarding_session_id).sum(:cost_usd).values
      avg_cost_per_session = if session_costs.any?
        session_costs.sum.to_f / session_costs.size
      else
        0.0
      end

      monthly_cost = users_per_month * AVG_SESSIONS_PER_USER * avg_cost_per_session

      {
        users_per_month: users_per_month,
        avg_sessions_per_user: AVG_SESSIONS_PER_USER,
        avg_cost_per_session: avg_cost_per_session.round(4),
        projected_monthly_cost: monthly_cost.round(2),
        projected_annual_cost: (monthly_cost * 12).round(2)
      }
    end
  end
end
