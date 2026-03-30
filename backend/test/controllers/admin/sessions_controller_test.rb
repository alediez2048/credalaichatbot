# frozen_string_literal: true

require "test_helper"

module Admin
  class SessionsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @admin = User.create!(email: "admin-sess@example.com", password: "password123", admin: true)
      @user = User.create!(email: "user-sess@example.com", password: "password123", admin: false)
      @session = OnboardingSession.create!(current_step: "welcome", status: "active")
      @session.messages.create!(role: "user", content: "hello", metadata: { channel: "web" })
    end

    teardown do
      @session.messages.delete_all
      @session.destroy
      @admin.destroy
      @user.destroy
    end

    test "admin can view session detail" do
      sign_in @admin
      get admin_session_path(@session)
      assert_response :success
      assert_select "h1", /Session ##{@session.id}/
      assert_select "h2", /Message timeline/
    end

    test "non-admin redirected" do
      sign_in @user
      get admin_session_path(@session)
      assert_redirected_to root_path
    end

    test "unknown session returns not found" do
      sign_in @admin
      get admin_session_path(9_999_999_999)
      assert_response :not_found
    end
  end
end
