# frozen_string_literal: true

module Sentiment
  class Tracker
    NEGATIVE_LABELS = %w[confused frustrated anxious].freeze
    ESCALATION_THRESHOLD = 2 # N consecutive negative readings = escalating

    class << self
      def record(session, label:, confidence:, signals: [])
        session.sentiment_readings.create!(
          label: label,
          confidence: confidence,
          signals: signals
        )
      end

      def recent_trend(session, n = 5)
        session.sentiment_readings.recent(n)
      end

      def current_sentiment(session)
        session.sentiment_readings.recent(1).first
      end

      # Detect if sentiment is worsening (consecutive negative readings)
      def escalating?(session)
        recent = recent_trend(session, ESCALATION_THRESHOLD + 1)
        return false if recent.size < ESCALATION_THRESHOLD

        last_n = recent.first(ESCALATION_THRESHOLD)
        last_n.all? { |r| NEGATIVE_LABELS.include?(r.label) }
      end
    end
  end
end
