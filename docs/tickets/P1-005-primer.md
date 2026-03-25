# P1-005 — Anonymous-to-authenticated session merge

**Priority:** P1
**Estimate:** 3 hours
**Phase:** 1 — AI Chatbot Core (MVP GATE)
**Status:** Not started

---

## Goal

When an anonymous user signs up or signs in, their existing anonymous `OnboardingSession` (along with all messages, documents, and bookings) is merged into their authenticated session. The user never loses progress — the conversation history, current step, and collected metadata carry over seamlessly. If the authenticated user already has a session, the anonymous session's data is appended and the more-advanced session state wins.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P1-005 |
|--------|----------------------|
| **P1-003** | Session persistence & resumption must work before merging sessions |
| **P1-002** | Orchestrator manages current_step, progress_percent, metadata that must be merged |

---

## Deliverables Checklist

- [ ] `Onboarding::SessionMerger` service — merges an anonymous session into an authenticated session
- [ ] Update `create_anonymous_session` in controller to populate `anonymous_token` via `SecureRandom.uuid`
- [ ] Devise hook (Warden callback) or controller callback that triggers merge after sign-in / sign-up
- [ ] Anonymous session's messages are re-parented to the authenticated session (preserving chronological order)
- [ ] Anonymous session's documents and bookings are re-parented
- [ ] Metadata from both sessions is deep-merged (authenticated session values win on conflict)
- [ ] The more-advanced `current_step` and higher `progress_percent` are kept
- [ ] Anonymous session is marked as `status: "merged"` (not destroyed) for audit trail
- [ ] `session[:onboarding_session_id]` is cleared after merge
- [ ] Unit tests for `SessionMerger` (happy path, no-op when no anonymous session, conflict resolution)
- [ ] Unit tests for the Devise hook / controller callback
- [ ] Integration test: anonymous user chats, signs up, sees merged history

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | Anonymous user's messages appear in authenticated session after sign-in | Chat as anon, sign in, reload `/onboarding` — all prior messages visible |
| 2 | Progress is preserved (not reset to zero) | Advance to `personal_info` as anon, sign in — `current_step` is still `personal_info` |
| 3 | Metadata is merged | Provide name as anon, sign in, provide email — both fields present in session metadata |
| 4 | No duplicate sessions for authenticated user | Sign in with existing session + anonymous session — only one active session remains |
| 5 | Anonymous session record is soft-deleted / marked merged | After merge, anonymous session has `status: "merged"` |
| 6 | Works for both sign-in and sign-up flows | Test with `devise/sessions#create` and `devise/registrations#create` |
| 7 | No-op when anonymous user has no session | Sign in without prior anonymous activity — no errors, normal session created |

---

## Technical Notes

### Current anonymous session flow

`OnboardingController#create_anonymous_session` creates an `OnboardingSession` with `user_id: nil` and stores its ID in `session[:onboarding_session_id]`. The `anonymous_token` column exists in the schema (indexed, unique) but is not currently populated during creation.

### Merge strategy

1. After Devise sign-in/sign-up, check `session[:onboarding_session_id]` for an anonymous session.
2. Find or create the authenticated user's `OnboardingSession`.
3. Call `Onboarding::SessionMerger.call(anonymous_session, authenticated_session)`.
4. Re-parent `messages`, `documents`, `bookings`, and `audit_logs` from anonymous to authenticated session.
5. Deep-merge `metadata` (authenticated values win on key conflict).
6. Take the higher `progress_percent` and more-advanced `current_step`.
7. Mark anonymous session as `status: "merged"`, store `merged_into_id` in its metadata.
8. Clear `session[:onboarding_session_id]`.

### Devise hook options

- **Option A:** Custom `after_sign_in_path_for` + `after_sign_up_path_for` in `ApplicationController` — simple but couples merge to path helpers.
- **Option B:** Warden callback (`Warden::Manager.after_authentication`) in an initializer — cleaner, fires for all Devise sign-in strategies.
- **Recommended:** Option B (Warden callback) for reliability, with a thin wrapper that calls `SessionMerger`.

### Step ordering for merge

```
welcome < personal_info < document_upload < scheduling < review < complete
```

The step that is further in this sequence wins during merge.

### Wrap in a transaction

The entire merge (re-parenting records, updating metadata, marking anonymous session) must run inside `ActiveRecord::Base.transaction` to avoid partial merges.

---

## Files to Create

| File | Purpose |
|------|---------|
| `app/services/onboarding/session_merger.rb` | Core merge logic: re-parent records, merge metadata, advance step |
| `config/initializers/session_merge.rb` | Warden `after_authentication` hook that triggers merge |
| `test/unit/onboarding/session_merger_test.rb` | Unit tests for merge service |
| `test/integration/session_merge_test.rb` | Integration test: anon chat -> sign in -> merged session |

## Files to Modify

| File | Changes |
|------|---------|
| `app/controllers/onboarding_controller.rb` | Update `create_anonymous_session` to set `anonymous_token` via `SecureRandom.uuid` |
| `app/models/onboarding_session.rb` | Add `scope :anonymous` and `scope :for_user`; add `merged?` convenience method |

---

## Files You Should READ Before Coding

1. `app/controllers/onboarding_controller.rb` — current anonymous session creation and lookup
2. `app/models/onboarding_session.rb` — associations (messages, documents, bookings, audit_logs)
3. `db/schema.rb` — `onboarding_sessions` columns (user_id, anonymous_token, current_step, progress_percent, metadata, status)
4. `config/initializers/devise.rb` — current Devise config
5. `app/models/user.rb` — `has_many :onboarding_sessions`
6. `config/routes.rb` — Devise routes

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All acceptance criteria verified
- [ ] `DEVLOG.md` updated with P1-005 entry
- [ ] Feature branch pushed; PR ready for review

---

## Suggested Branch

```bash
git switch -c feature/P1-005-session-merge
```

---

## Out of Scope for P1-005

- Session expiration / TTL (future ticket)
- Merging sessions across multiple devices (only browser session cookie is used)
- Admin UI for viewing merged sessions
- OAuth / SSO sign-in flows (only Devise database_authenticatable)
- Rate limiting (P1-006)
