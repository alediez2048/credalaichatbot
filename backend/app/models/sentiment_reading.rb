# frozen_string_literal: true

class SentimentReading < ApplicationRecord
  belongs_to :onboarding_session

  LABELS = %w[positive neutral confused frustrated anxious].freeze

  validates :label, inclusion: { in: LABELS }
  validates :confidence, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }, allow_nil: true

  scope :recent, ->(n = 5) { order(created_at: :desc).limit(n) }
  scope :for_session, ->(session) { where(onboarding_session: session) }
end
