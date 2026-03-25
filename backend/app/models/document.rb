# frozen_string_literal: true

class Document < ApplicationRecord
  belongs_to :onboarding_session
  has_many :extracted_fields, dependent: :destroy
  has_one_attached :file

  ALLOWED_CONTENT_TYPES = %w[image/png image/jpeg application/pdf].freeze
  MAX_FILE_SIZE = 10.megabytes

  validate :validate_file_attachment, if: -> { file.attached? }

  private

  def validate_file_attachment
    unless ALLOWED_CONTENT_TYPES.include?(file.content_type)
      errors.add(:file, "must be PNG, JPEG, or PDF")
    end
    if file.byte_size > MAX_FILE_SIZE
      errors.add(:file, "must be less than 10 MB")
    end
  end
end
