# frozen_string_literal: true

namespace :cost do
  desc "Show per-session and aggregate cost summary"
  task report: :environment do
    usages = LLMUsage.group(:onboarding_session_id)

    session_costs = usages.sum(:cost_usd)
    session_tokens = usages.sum(:total_tokens)

    if session_costs.empty?
      puts "No usage data found."
      next
    end

    puts "=" * 60
    puts "Cost Report"
    puts "=" * 60
    puts ""
    puts format("%-12s %12s %12s", "Session", "Tokens", "Cost (USD)")
    puts "-" * 40

    session_costs.each do |session_id, cost|
      tokens = session_tokens[session_id] || 0
      puts format("%-12s %12d $%11.6f", session_id, tokens, cost)
    end

    total_cost = session_costs.values.sum
    total_tokens = session_tokens.values.sum

    puts "-" * 40
    puts format("%-12s %12d $%11.6f", "TOTAL", total_tokens, total_cost)
    puts ""
    puts "Sessions: #{session_costs.size}"
    puts "Avg cost/session: $#{(total_cost / session_costs.size).round(6)}"
  end

  desc "Project monthly cost at N users/month"
  task :project, [:users_per_month] => :environment do |_t, args|
    users = (args[:users_per_month] || 1000).to_i
    projection = Cost::Projector.project(users_per_month: users)

    puts "=" * 60
    puts "Cost Projection — #{users} users/month"
    puts "=" * 60
    puts ""
    puts "Avg sessions/user:     #{projection[:avg_sessions_per_user]}"
    puts "Avg cost/session:      $#{projection[:avg_cost_per_session]}"
    puts "Projected monthly:     $#{projection[:projected_monthly_cost]}"
    puts "Projected annual:      $#{projection[:projected_annual_cost]}"
  end
end
