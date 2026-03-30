# frozen_string_literal: true

module Admin
  class DashboardController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin

    def index
      @stats = Admin::DashboardStats.call(
        status: params[:status],
        channel: params[:channel],
        date_from: params[:date_from],
        date_to: params[:date_to]
      )
    end

    private

    def require_admin
      unless current_user.admin?
        redirect_to root_path, alert: "Access denied. Admin privileges required."
      end
    end
  end
end
