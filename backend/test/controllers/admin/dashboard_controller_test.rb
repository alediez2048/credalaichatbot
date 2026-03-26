# frozen_string_literal: true

require "test_helper"

module Admin
  class DashboardControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @admin = User.create!(email: "admin@example.com", password: "password123", admin: true)
      @user = User.create!(email: "user@example.com", password: "password123", admin: false)
    end

    teardown do
      @admin.destroy
      @user.destroy
    end

    test "admin user can access dashboard" do
      sign_in @admin
      get admin_dashboard_path
      assert_response :success
      assert_select "h1", /Admin Dashboard/
    end

    test "non-admin user is redirected" do
      sign_in @user
      get admin_dashboard_path
      assert_redirected_to root_path
      assert_equal "Access denied. Admin privileges required.", flash[:alert]
    end

    test "unauthenticated user is redirected to login" do
      get admin_dashboard_path
      assert_response :redirect
    end

    test "dashboard renders session stats" do
      sign_in @admin
      get admin_dashboard_path
      assert_response :success
      assert_select "p", /Total Sessions/
    end

    test "dashboard renders recent sessions table" do
      sign_in @admin
      get admin_dashboard_path
      assert_response :success
      assert_select "h2", /Recent Sessions/
    end
  end
end
