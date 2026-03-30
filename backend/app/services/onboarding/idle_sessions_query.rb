# frozen_string_literal: true

module Onboarding
  class IdleSessionsQuery
    DEFAULT_IDLE_THRESHOLD = 2.hours
    DEFAULT_NUDGE_COOLDOWN = 24.hours

    # @param idle_threshold [ActiveSupport::Duration] how long since last interaction to count as idle
    # @param nudge_cooldown [ActiveSupport::Duration] minimum gap between nudges for one session
    # @return [ActiveRecord::Relation<OnboardingSession>]
    def self.call(idle_threshold: DEFAULT_IDLE_THRESHOLD, nudge_cooldown: DEFAULT_NUDGE_COOLDOWN)
      cutoff = idle_threshold.ago

      recently_nudged_ids = SmsEvent
        .where(direction: "outbound")
        .where("metadata @> ?", { nudge: true }.to_json)
        .where("created_at > ?", nudge_cooldown.ago)
        .select(:onboarding_session_id)

      scope = OnboardingSession
        .where(status: "active")
        .where("last_interaction_at < ?", cutoff)
        .where.not(id: recently_nudged_ids)

      scope.where(
        "((phone_number IS NOT NULL AND sms_opt_in = true) OR (channel_type IS NOT NULL AND channel_user_id IS NOT NULL))"
      )
    end
  end
end
