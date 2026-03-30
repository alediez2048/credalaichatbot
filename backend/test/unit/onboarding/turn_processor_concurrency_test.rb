# frozen_string_literal: true

require "test_helper"

module Onboarding
  # Verifies session-level locking: two concurrent turns must not interleave DB writes.
  class TurnProcessorConcurrencyTest < ActiveSupport::TestCase
    test "concurrent turns on same session produce four messages" do
      session = OnboardingSession.create!(current_step: "welcome", status: "active")

      Onboarding::Orchestrator.class_eval do
        alias_method :__process_backup_for_concurrency_test, :process
        def process(_user_message, is_eval: false)
          sleep 0.03
          { content: "ok", step_changed: false, error: nil }
        end
      end

      threads = 2.times.map do |i|
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            TurnProcessor.process(session: session, body: "m#{i}", channel: :web)
          end
        end
      end
      threads.each(&:join)

      assert_equal 4, session.reload.messages.count
    ensure
      Onboarding::Orchestrator.class_eval do
        alias_method :process, :__process_backup_for_concurrency_test
        remove_method :__process_backup_for_concurrency_test
      end
    end
  end
end
