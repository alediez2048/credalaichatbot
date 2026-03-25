# frozen_string_literal: true

module Onboarding
  class SessionMerger
    STEP_ORDER = Onboarding::Orchestrator::STEP_NAMES

    # Merges an anonymous session into an authenticated session.
    # Re-parents all child records, deep-merges metadata, keeps the more
    # advanced step and higher progress, then marks the anonymous session
    # as merged.
    #
    # @param anonymous_session [OnboardingSession, nil]
    # @param authenticated_session [OnboardingSession]
    # @return [OnboardingSession] the authenticated session
    def self.call(anonymous_session, authenticated_session)
      return authenticated_session if anonymous_session.nil?
      return authenticated_session if anonymous_session.id == authenticated_session.id

      ActiveRecord::Base.transaction do
        # Re-parent child records
        anonymous_session.messages.update_all(onboarding_session_id: authenticated_session.id)
        anonymous_session.documents.update_all(onboarding_session_id: authenticated_session.id)
        anonymous_session.bookings.update_all(onboarding_session_id: authenticated_session.id)
        anonymous_session.audit_logs.update_all(onboarding_session_id: authenticated_session.id)

        # Deep-merge metadata (authenticated values win on conflict)
        anon_meta = (anonymous_session.metadata || {}).except("_pending_advance")
        auth_meta = authenticated_session.metadata || {}
        merged_metadata = anon_meta.deep_merge(auth_meta)

        # Keep more advanced step
        anon_step_idx = STEP_ORDER.index(anonymous_session.current_step) || 0
        auth_step_idx = STEP_ORDER.index(authenticated_session.current_step) || 0
        best_step = anon_step_idx >= auth_step_idx ? anonymous_session.current_step : authenticated_session.current_step

        # Keep higher progress
        best_progress = [
          anonymous_session.progress_percent || 0,
          authenticated_session.progress_percent || 0
        ].max

        authenticated_session.update!(
          metadata: merged_metadata,
          current_step: best_step,
          progress_percent: best_progress
        )

        # Mark anonymous session as merged
        anonymous_session.update!(
          status: "merged",
          metadata: (anonymous_session.metadata || {}).merge("merged_into_id" => authenticated_session.id)
        )
      end

      authenticated_session
    end
  end
end
