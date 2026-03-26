# frozen_string_literal: true

module Admin
  class DashboardStats
    ONBOARDING_STEPS = %w[welcome personal_info document_upload scheduling review complete].freeze

    def self.call
      {
        session_stats: session_stats,
        step_funnel: step_funnel,
        cost_summary: cost_summary,
        eval_summary: eval_summary,
        recent_sessions: recent_sessions
      }
    end

    def self.session_stats
      sessions = OnboardingSession.all
      completed = sessions.where(current_step: "complete")
      {
        total: sessions.count,
        completed: completed.count,
        active: sessions.where("updated_at > ?", 30.minutes.ago).where.not(current_step: "complete").count,
        completion_rate: sessions.count > 0 ? (completed.count * 100.0 / sessions.count).round(1) : 0.0,
        avg_completion_minutes: avg_completion_time(completed)
      }
    end

    def self.step_funnel
      counts = OnboardingSession.group(:current_step).count
      total = counts.values.sum.to_f

      ONBOARDING_STEPS.map do |step|
        count = counts[step] || 0
        pct = total > 0 ? (count * 100.0 / total).round(1) : 0.0
        { step: step, count: count, percent: pct }
      end
    end

    def self.cost_summary
      usages = LLMUsage.all
      total_cost = usages.sum(:cost_usd)
      session_count = usages.select(:onboarding_session_id).distinct.count

      {
        total_cost: total_cost.round(4),
        avg_cost_per_session: session_count > 0 ? (total_cost / session_count).round(4) : 0.0,
        last_7_days_cost: usages.where(created_at: 7.days.ago..).sum(:cost_usd).round(4),
        total_tokens: usages.sum(:total_tokens)
      }
    end

    def self.eval_summary
      report_path = Rails.root.join("tmp/eval_report.json")
      return nil unless File.exist?(report_path)

      data = JSON.parse(File.read(report_path))
      {
        pass_rate: data["pass_rate"],
        total: data["total"],
        passed: data["passed"],
        failed: data["failed"],
        failures: (data["failures"] || []).first(5),
        timestamp: data["timestamp"]
      }
    rescue JSON::ParserError
      nil
    end

    def self.recent_sessions(limit: 20)
      OnboardingSession
        .includes(:messages, :llm_usages)
        .order(created_at: :desc)
        .limit(limit)
        .map do |s|
          {
            id: s.id,
            user_id: s.user_id,
            current_step: s.current_step,
            progress_percent: s.progress_percent,
            message_count: s.messages.size,
            cost: s.llm_usages.sum(&:cost_usd).round(4),
            created_at: s.created_at
          }
        end
    end

    def self.avg_completion_time(completed_sessions)
      return 0.0 if completed_sessions.count == 0

      durations = completed_sessions.pluck(:created_at, :updated_at).map { |c, u| (u - c) / 60.0 }
      (durations.sum / durations.size).round(1)
    end
    private_class_method :avg_completion_time
  end
end
