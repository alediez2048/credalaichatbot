# frozen_string_literal: true

require "securerandom"

module Scheduling
  class CalendarGenerator
    class << self
      # Generate an ICS calendar file for a booking
      # @param booking [Booking]
      # @return [String] ICS content
      def generate(booking)
        dtstart = booking.starts_at.utc.strftime("%Y%m%dT%H%M%SZ")
        dtend = (booking.starts_at + (booking.duration_minutes || 30).minutes).utc.strftime("%Y%m%dT%H%M%SZ")
        uid = "booking-#{booking.id}@credal.ai"
        now = Time.current.utc.strftime("%Y%m%dT%H%M%SZ")

        <<~ICS
          BEGIN:VCALENDAR
          VERSION:2.0
          PRODID:-//Credal.ai//Onboarding//EN
          BEGIN:VEVENT
          UID:#{uid}
          DTSTAMP:#{now}
          DTSTART:#{dtstart}
          DTEND:#{dtend}
          SUMMARY:#{booking.service_type&.humanize} - Credal Onboarding
          DESCRIPTION:Your #{booking.service_type} appointment for onboarding.
          STATUS:CONFIRMED
          END:VEVENT
          END:VCALENDAR
        ICS
      end

      # Generate a secure token for calendar download
      def generate_token(booking)
        token = SecureRandom.urlsafe_base64(32)
        booking.update!(metadata: (booking.metadata || {}).merge("calendar_token" => token))
        token
      end

      # Validate a calendar download token
      def valid_token?(booking, token)
        return false if token.blank?
        booking.metadata&.dig("calendar_token") == token
      end
    end
  end
end
