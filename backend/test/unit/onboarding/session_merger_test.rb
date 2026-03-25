# frozen_string_literal: true

require "test_helper"

module Onboarding
  class SessionMergerTest < ActiveSupport::TestCase
    def setup
      @anon_session = OnboardingSession.create!(
        user_id: nil,
        anonymous_token: SecureRandom.uuid,
        status: "active",
        current_step: "welcome",
        progress_percent: 0,
        metadata: {}
      )
      @user = User.create!(email: "test@example.com", password: "password123456")
      @auth_session = OnboardingSession.create!(
        user_id: @user.id,
        status: "active",
        current_step: "welcome",
        progress_percent: 0,
        metadata: {}
      )
    end

    test "merges messages from anonymous to authenticated session" do
      msg1 = Message.create!(onboarding_session: @anon_session, role: "user", content: "Hello")
      msg2 = Message.create!(onboarding_session: @anon_session, role: "assistant", content: "Hi there")
      auth_msg = Message.create!(onboarding_session: @auth_session, role: "user", content: "Existing")

      Onboarding::SessionMerger.call(@anon_session, @auth_session)

      assert_equal @auth_session.id, msg1.reload.onboarding_session_id
      assert_equal @auth_session.id, msg2.reload.onboarding_session_id
      assert_equal @auth_session.id, auth_msg.reload.onboarding_session_id
      assert_equal 3, @auth_session.messages.count
    end

    test "deep-merges metadata with authenticated values winning" do
      @anon_session.update!(metadata: { "a" => 1, "b" => 2 })
      @auth_session.update!(metadata: { "b" => 3, "c" => 4 })

      Onboarding::SessionMerger.call(@anon_session, @auth_session)

      @auth_session.reload
      assert_equal 1, @auth_session.metadata["a"]
      assert_equal 3, @auth_session.metadata["b"]
      assert_equal 4, @auth_session.metadata["c"]
    end

    test "excludes _pending_advance key from metadata merge" do
      @anon_session.update!(metadata: { "a" => 1, "_pending_advance" => "scheduling" })
      @auth_session.update!(metadata: { "b" => 2 })

      Onboarding::SessionMerger.call(@anon_session, @auth_session)

      @auth_session.reload
      assert_equal 1, @auth_session.metadata["a"]
      assert_equal 2, @auth_session.metadata["b"]
      assert_nil @auth_session.metadata["_pending_advance"]
    end

    test "keeps more advanced current_step" do
      @anon_session.update!(current_step: "personal_info")
      @auth_session.update!(current_step: "welcome")

      Onboarding::SessionMerger.call(@anon_session, @auth_session)

      @auth_session.reload
      assert_equal "personal_info", @auth_session.current_step
    end

    test "keeps higher progress_percent" do
      @anon_session.update!(progress_percent: 40)
      @auth_session.update!(progress_percent: 20)

      Onboarding::SessionMerger.call(@anon_session, @auth_session)

      @auth_session.reload
      assert_equal 40, @auth_session.progress_percent
    end

    test "marks anonymous session as merged" do
      Onboarding::SessionMerger.call(@anon_session, @auth_session)

      @anon_session.reload
      assert_equal "merged", @anon_session.status
      assert_equal @auth_session.id, @anon_session.metadata["merged_into_id"]
    end

    test "no-op when anonymous session is nil" do
      assert_nothing_raised do
        result = Onboarding::SessionMerger.call(nil, @auth_session)
        assert_equal @auth_session, result
      end
    end

    test "no-op when sessions are the same" do
      assert_nothing_raised do
        result = Onboarding::SessionMerger.call(@auth_session, @auth_session)
        assert_equal @auth_session, result
      end
    end

    test "re-parents documents and bookings" do
      doc = Document.create!(
        onboarding_session: @anon_session,
        document_type: "id_card",
        storage_key: "uploads/test.pdf",
        content_type: "application/pdf",
        byte_size: 1024
      )
      booking = Booking.create!(
        onboarding_session: @anon_session,
        starts_at: 1.day.from_now,
        duration_minutes: 30,
        service_type: "consultation"
      )

      Onboarding::SessionMerger.call(@anon_session, @auth_session)

      assert_equal @auth_session.id, doc.reload.onboarding_session_id
      assert_equal @auth_session.id, booking.reload.onboarding_session_id
    end

    test "wraps everything in a transaction" do
      msg = Message.create!(onboarding_session: @anon_session, role: "user", content: "Hello")
      @anon_session.update!(current_step: "personal_info", progress_percent: 40)

      # Stub update_all on bookings to raise, simulating a failure mid-merge
      error_raised = false
      original_method = @anon_session.bookings.method(:update_all)

      @anon_session.bookings.define_singleton_method(:update_all) do |*args|
        raise ActiveRecord::StatementInvalid, "simulated failure"
      end

      begin
        Onboarding::SessionMerger.call(@anon_session, @auth_session)
      rescue ActiveRecord::StatementInvalid
        error_raised = true
      end

      assert error_raised, "Expected an error to be raised"

      # Nothing should have changed because the transaction rolled back
      msg.reload
      assert_equal @anon_session.id, msg.onboarding_session_id
      @anon_session.reload
      assert_not_equal "merged", @anon_session.status
    end
  end
end
