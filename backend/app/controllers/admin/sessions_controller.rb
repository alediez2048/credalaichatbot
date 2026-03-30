# frozen_string_literal: true

module Admin
  class SessionsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin

    def show
      @detail = Admin::SessionDetailStats.call(params[:id])
      return head :not_found if @detail.nil?
    end

    private

    def require_admin
      return if current_user.admin?

      redirect_to root_path, alert: "Access denied. Admin privileges required."
    end
  end
end
