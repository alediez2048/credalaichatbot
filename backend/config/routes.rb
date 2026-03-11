# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users
  root "home#index"
  get "/onboarding", to: "onboarding#chat", as: :onboarding
  get "up" => "rails/health#show", as: :rails_health_check
end
