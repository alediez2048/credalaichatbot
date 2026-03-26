# frozen_string_literal: true

# P5-003: renamed from LlmUsage to match Rails inflection of llm_usages table
class LLMUsage < ApplicationRecord
  self.table_name = "llm_usages"

  belongs_to :onboarding_session

  scope :for_session, ->(session_id) { where(onboarding_session_id: session_id) }
  scope :recent, ->(days: 30) { where(created_at: days.days.ago..) }
end
