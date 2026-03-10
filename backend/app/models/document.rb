# frozen_string_literal: true

class Document < ApplicationRecord
  belongs_to :onboarding_session
  has_many :extracted_fields, dependent: :destroy
end
