# frozen_string_literal: true

module Messaging
  # Maps OpenClaw (or other gateway) channel identity to an OnboardingSession.
  class IdentityResolver
    class << self
      # @param channel_type [String] e.g. telegram, whatsapp, discord
      # @param sender_id [String] stable sender id from the gateway
      # @param phone_number [String, nil] optional E.164 or raw; links to opted-in SMS session when present
      # @return [OnboardingSession]
      def find_or_create_session!(channel_type:, sender_id:, phone_number: nil)
        ct = channel_type.to_s.downcase.strip
        sid = sender_id.to_s.strip
        raise ArgumentError, "channel_type is blank" if ct.blank?
        raise ArgumentError, "sender_id is blank" if sid.blank?

        existing = OnboardingSession.find_by(channel_type: ct, channel_user_id: sid)
        return existing if existing

        linked = link_via_phone(ct, sid, phone_number)
        return linked if linked

        OnboardingSession.create!(
          current_step: "welcome",
          status: "active",
          channel_type: ct,
          channel_user_id: sid,
          last_channel: "openclaw"
        )
      end

      private

      def link_via_phone(channel_type, sender_id, phone_number)
        return nil if phone_number.blank?

        norm = Messaging::PhoneNumber.normalize(phone_number)
        return nil if norm.blank?

        phone_session = OnboardingSession.sms_opted_in.where(phone_number: norm).order(updated_at: :desc).first
        return nil unless phone_session

        conflict = OnboardingSession.where(channel_type: channel_type, channel_user_id: sender_id).where.not(id: phone_session.id).exists?
        return nil if conflict

        phone_session.update!(channel_type: channel_type, channel_user_id: sender_id, last_channel: "openclaw")
        phone_session.reload
      end
    end
  end
end
