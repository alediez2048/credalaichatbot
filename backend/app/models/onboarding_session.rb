# frozen_string_literal: true

class OnboardingSession < ApplicationRecord
  belongs_to :user, optional: true
  has_many :messages, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_many :audit_logs, dependent: :destroy
end
