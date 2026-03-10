# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :onboarding_sessions, dependent: :destroy
  has_many :audit_logs, dependent: :nullify
end
