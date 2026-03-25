# frozen_string_literal: true

module Api
  class BookingsController < ApplicationController
    skip_before_action :verify_authenticity_token

    # GET /api/bookings/:id/calendar.ics?token=X
    def calendar
      booking = Booking.find_by(id: params[:id])
      unless booking
        render plain: "Booking not found", status: :not_found
        return
      end

      unless Scheduling::CalendarGenerator.valid_token?(booking, params[:token])
        render plain: "Invalid or expired link", status: :forbidden
        return
      end

      ics = Scheduling::CalendarGenerator.generate(booking)
      send_data ics,
        filename: "credal-booking-#{booking.id}.ics",
        type: "text/calendar",
        disposition: "attachment"
    end
  end
end
