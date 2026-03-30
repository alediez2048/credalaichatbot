# frozen_string_literal: true

class SmsEvent < ApplicationRecord
  belongs_to :onboarding_session, optional: true

  validates :provider, presence: true
  validates :direction, presence: true, inclusion: { in: %w[inbound outbound] }
  validates :status, presence: true
end
