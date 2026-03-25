# frozen_string_literal: true

class OnboardingController < ApplicationController
  def chat
    @onboarding_session = find_or_create_onboarding_session
  end

  private

  def find_or_create_onboarding_session
    if current_user
      OnboardingSession.find_or_create_by!(user_id: current_user.id) do |s|
        s.status = "active"
      end
    else
      id = session[:onboarding_session_id]
      if id.present?
        OnboardingSession.find_by(id: id) || create_anonymous_session
      else
        create_anonymous_session
      end
    end
  end

  def create_anonymous_session
    s = OnboardingSession.create!(user_id: nil, status: "active")
    session[:onboarding_session_id] = s.id
    s
  end
end
