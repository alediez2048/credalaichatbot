# frozen_string_literal: true

module Api
  module Admin
    class IdleSessionsController < BaseController
      before_action :ensure_nudge_enabled

      def index
        sessions = Onboarding::IdleSessionsQuery.call
        render json: {
          sessions: sessions.map { |s|
            {
              id: s.id,
              current_step: s.current_step,
              last_channel: s.last_channel,
              last_interaction_at: s.last_interaction_at&.iso8601,
              channel_type: s.channel_type,
              channel_user_id: s.channel_user_id,
              phone_number: s.phone_number
            }
          }
        }
      end

      private

      def ensure_nudge_enabled
        return if ActiveModel::Type::Boolean.new.cast(ENV.fetch("PROACTIVE_NUDGE_ENABLED", "false"))

        render json: { error: "proactive nudge disabled" }, status: :not_found
      end
    end
  end
end
