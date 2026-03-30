# frozen_string_literal: true

module Api
  module Admin
    class BaseController < ApplicationController
      skip_before_action :verify_authenticity_token

      before_action :ensure_openclaw_enabled
      before_action :authenticate_hook_token

      private

      def ensure_openclaw_enabled
        return if ActiveModel::Type::Boolean.new.cast(ENV.fetch("OPENCLAW_ENABLED", "false"))

        render json: { error: "openclaw disabled" }, status: :not_found
      end

      def authenticate_hook_token
        return if performed?

        expected = ENV["OPENCLAW_HOOKS_TOKEN"].to_s
        if expected.blank?
          render json: { error: "openclaw hooks not configured" }, status: :service_unavailable
          return
        end

        supplied = request.headers["X-Openclaw-Token"].presence
        if supplied.blank?
          auth = request.headers["Authorization"].to_s
          supplied = auth.sub(/\ABearer\s+/i, "").strip if auth.match?(/\ABearer\s+/i)
        end

        unless supplied.present? && ActiveSupport::SecurityUtils.secure_compare(supplied, expected)
          render json: { error: "unauthorized" }, status: :unauthorized
        end
      end
    end
  end
end
