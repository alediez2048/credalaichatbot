# frozen_string_literal: true

module Documents
  class AuditLogger
    class << self
      # @param action [String] e.g., "document_upload", "extraction_access", "field_correction"
      # @param session [OnboardingSession, nil]
      # @param resource [ActiveRecord::Base, nil] the resource being accessed
      # @param user [User, nil]
      # @param payload [Hash] additional context
      def log(action:, session: nil, resource: nil, user: nil, payload: {})
        AuditLog.create!(
          action: action,
          onboarding_session_id: session&.id,
          user_id: user&.id,
          resource_type: resource&.class&.name,
          resource_id: resource&.id&.to_s,
          payload: payload
        )
      end
    end
  end
end
