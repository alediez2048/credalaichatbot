# frozen_string_literal: true

# Merge anonymous onboarding sessions into the authenticated user's session
# when they sign in or sign up via Devise/Warden.
Warden::Manager.after_authentication do |user, auth, _opts|
  anon_session_id = auth.request.session[:onboarding_session_id]
  if anon_session_id.present?
    anon_session = OnboardingSession.find_by(id: anon_session_id, user_id: nil)
    if anon_session
      auth_session = OnboardingSession.find_or_create_by!(user_id: user.id) { |s| s.status = "active" }
      Onboarding::SessionMerger.call(anon_session, auth_session)
      auth.request.session.delete(:onboarding_session_id)
    end
  end
end
