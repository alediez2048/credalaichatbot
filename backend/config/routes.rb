# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users
  root "home#index"
  get "/onboarding", to: "onboarding#chat", as: :onboarding
  post "/onboarding/reset", to: "onboarding#reset", as: :onboarding_reset
  namespace :api do
    resources :documents, only: [:create]
    resources :extracted_fields, only: [:update]
  end
  get "up" => "rails/health#show", as: :rails_health_check
end
