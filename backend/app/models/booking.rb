# frozen_string_literal: true

class Booking < ApplicationRecord
  belongs_to :onboarding_session
  belongs_to :appointment_slot, optional: true
end
