# frozen_string_literal: true

class OnboardingSession < ApplicationRecord
  belongs_to :user, optional: true
  has_many :messages, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_many :audit_logs, dependent: :destroy
  has_many :sentiment_readings, dependent: :destroy
  has_many :llm_usages, class_name: "LLMUsage", dependent: :destroy
  has_many :sms_events, dependent: :nullify

  scope :anonymous, -> { where(user_id: nil) }
  scope :for_user, ->(user) { where(user: user) }
  scope :sms_opted_in, -> { where(sms_opt_in: true) }

  before_validation :normalize_phone_number

  validates :last_channel, inclusion: { in: %w[web sms openclaw] }

  def merged?
    status == "merged"
  end

  def sms_opted_in?
    sms_opt_in && phone_number.present?
  end

  private

  def normalize_phone_number
    phone_number_was_present = phone_number.present?
    self.phone_number = Messaging::PhoneNumber.normalize(phone_number) if phone_number_was_present
  rescue => _e
    # Keep existing value if normalization fails unexpectedly.
  end
end
