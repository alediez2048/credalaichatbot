# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users
  root "home#index"
  get "/onboarding", to: "onboarding#chat", as: :onboarding
  post "/onboarding/reset", to: "onboarding#reset", as: :onboarding_reset
  namespace :api do
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
  get "up" => "rails/health#show", as: :rails_health_check
end
