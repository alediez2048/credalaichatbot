# frozen_string_literal: true

module Admin
  # Message / duration / sentiment aggregates for admin dashboard (P7-006).
  class InteractionAnalytics
    def self.call
      sessions = OnboardingSession.includes(:messages).to_a
      {
        avg_user_messages_per_session: avg_count(sessions) { |s| s.messages.count { |m| m.role == "user" } },
        avg_assistant_messages_per_session: avg_count(sessions) { |s| s.messages.count { |m| m.role == "assistant" } },
        avg_session_duration_minutes: avg_duration_minutes(sessions),
        sessions_with_error_messages: sessions.count { |s| s.messages.any? { |m| truthy?(m.metadata["error"]) } },
        sentiment_distribution: sentiment_distribution,
        llm_usage_by_model: LLMUsage.group(:model).count
      }
    end

    def self.avg_count(sessions)
      return 0.0 if sessions.empty?

      vals = sessions.map { |s| yield(s) }
      (vals.sum.to_f / vals.size).round(2)
    end

    def self.avg_duration_minutes(sessions)
      durations = sessions.filter_map do |s|
        msgs = s.messages.sort_by(&:created_at)
        next nil if msgs.size < 2

        ((msgs.last.created_at - msgs.first.created_at) / 60.0)
      end
      return 0.0 if durations.empty?

      (durations.sum / durations.size).round(1)
    end

    def self.truthy?(v)
      ActiveModel::Type::Boolean.new.cast(v)
    end

    def self.sentiment_distribution
      total = SentimentReading.count
      return {} if total.zero?

      SentimentReading.group(:label).count.transform_values do |c|
        (c * 100.0 / total).round(1)
      end
    end
  end
end
