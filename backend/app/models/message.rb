# frozen_string_literal: true

class Message < ApplicationRecord
  belongs_to :onboarding_session

  validates :role, presence: true, inclusion: { in: %w[user assistant system tool] }
end
