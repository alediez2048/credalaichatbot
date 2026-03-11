# frozen_string_literal: true

class OnboardingController < ApplicationController
  # No auth required — anonymous users can access; auth enforced at document upload (P1-005)
  def chat
  end
end
