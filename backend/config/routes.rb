# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users
  root "home#index"
  get "/onboarding", to: "onboarding#chat", as: :onboarding
  post "/onboarding/reset", to: "onboarding#reset", as: :onboarding_reset
  namespace :api do
    post "openclaw/turn", to: "openclaw_turns#create"

    patch "onboarding_sessions/:onboarding_session_id/sms_settings", to: "onboarding_sms_settings#update"
    post "onboarding_sessions/:onboarding_session_id/sms_handoff", to: "onboarding_sms_settings#handoff"

    resources :documents, only: [:create]
    resources :extracted_fields, only: [:update]
    resources :bookings, only: [] do
      member do
        get "calendar", to: "bookings#calendar"
      end
    end
  end
  namespace :admin do
    get "dashboard", to: "dashboard#index", as: :dashboard
  end

  namespace :webhooks do
    post "sms/twilio", to: "sms#twilio"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
