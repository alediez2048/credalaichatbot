# P7-001 — Live web->SMS continuation foundation (phone capture + consent + resume)

**Priority:** P7  
**Estimate:** 4 hours  
**Phase:** 7 — Omnichannel Continuity  
**Status:** Proposed

---

## Goal

Enable a live demo flow where users start onboarding on web and continue via SMS from the same step, by collecting phone number + explicit consent and binding the phone identity to the existing onboarding session.

---

## Why this phase exists

Main problem statement today: users abandon onboarding when forced through long, fragmented flows without timely support.

P7 addresses this directly by adding a second channel (SMS) to resume progress asynchronously rather than restarting later.

---

## Deliverables Checklist

- [x] Add phone + SMS consent capture in onboarding flow (with explicit opt-in language) — Chat UI panel on `/onboarding`
- [x] Persist `phone_number` and `sms_opt_in` on the session/user profile — migration + `PATCH /api/onboarding_sessions/:id/sms_settings`
- [x] Add session-channel metadata (`last_channel`, `last_interaction_at`, `sms_thread_id`) — migration (thread id reserved for future)
- [x] Add resumable handoff message when user leaves web before completion — `POST .../sms_handoff` sends SMS with onboarding link + reply hint
- [x] Add unit tests for consent validation and phone normalization
- [ ] Add integration test: start on web, resume same session via SMS — covered by processor + webhook tests; full E2E optional
- [x] Add deterministic demo trigger in UI/flow: "Text me a link to continue"

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | User can provide phone and opt into SMS | Manual: onboarding asks for phone and consent; values persist |
| 2 | SMS channel resumes same onboarding step | Integration test: continue from previous `current_step` |
| 3 | No consent means no SMS outreach | Unit/integration tests for opt-out behavior |
| 4 | Session identity remains consistent across channels | Assert same `onboarding_session_id` in both channel events |
| 5 | Demo can show web -> SMS resume in under 60 seconds | Manual demo script check |

---

## Files You Will Likely Modify

- `backend/app/services/onboarding/orchestrator.rb`
- `backend/app/models/onboarding_session.rb`
- `backend/app/services/tools/router.rb`
- `backend/config/prompts/onboarding_steps.yml`
- `backend/test/unit/...` and `backend/test/integration/...`

---

## Architecture Notes

- Keep **one source of truth**: `OnboardingSession` remains authoritative regardless of channel.
- Do not create separate web and SMS flows; channel is transport, not business logic.
- Preserve module boundaries: messaging provider integration stays behind an adapter layer.
- Provider choice for this ticket is not fixed; this ticket only prepares shared channel/session foundations.

---

## Definition of Done

- [ ] Deliverables complete
- [ ] Tests pass
- [ ] `DEVLOG.md` updated
- [ ] Feature branch pushed; PR ready
