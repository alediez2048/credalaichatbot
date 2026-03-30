# frozen_string_literal: true

module Api
  module Admin
    class OpenclawStatusController < BaseController
      def show
        render json: {
          openclaw_enabled: true,
          proactive_nudge_enabled: ActiveModel::Type::Boolean.new.cast(ENV.fetch("PROACTIVE_NUDGE_ENABLED", "false")),
          gateway_url: ENV.fetch("OPENCLAW_GATEWAY_URL", "http://127.0.0.1:18789")
        }
      end
    end
  end
end
