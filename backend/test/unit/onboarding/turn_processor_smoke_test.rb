# frozen_string_literal: true

require "test_helper"

module Onboarding
  class TurnProcessorSmokeTest < ActiveSupport::TestCase
    test "rejects blank body" do
      session = OnboardingSession.create!(current_step: "welcome", status: "active")
      assert_raises(ArgumentError) do
        TurnProcessor.process(session: session, body: "   ", channel: :web)
      end
    end
  end
end
