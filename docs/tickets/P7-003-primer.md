# P7-003 — Cross-channel orchestration + conflict handling

**Priority:** P7  
**Estimate:** 4 hours  
**Phase:** 7 — Omnichannel Continuity  
**Status:** Done

---

## Goal

Ensure onboarding orchestration behaves consistently across web and SMS while preventing race conditions when both channels are active.

---

## Deliverables Checklist

- [x] Channel-aware turn metadata (`channel`, `message_id`, `provider_message_id`)
- [x] Concurrency guard for same-session multi-channel turns (`OnboardingSession#with_lock` in `TurnProcessor`)
- [x] Conflict policy (lock-and-serialize; one turn completes before the next)
- [x] Unified fallback/error messaging by channel (`ChannelFormatter.format_error`)
- [x] Integration tests for simultaneous web + SMS activity (concurrency test + formatter tests)
- [x] Explicit resume confirmation copy when switching channels (web↔SMS prefixes in `ChannelFormatter`)

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | Same orchestrator path used for web and SMS | `TurnProcessor` used from Action Cable + `InboundProcessor` |
| 2 | Concurrent turns do not corrupt state | `turn_processor_concurrency_test` (four messages, no interleaving) |
| 3 | Channel-specific formatting works | `channel_formatter_test` (SMS truncation, web rich) |
| 4 | Session progress remains monotonic | Lock ensures ordered turns; assertions on message count |
| 5 | User receives clear channel-switch context | Formatter prefix assertions + manual spot-check |

---

## Definition of Done

- [x] Deliverables complete
- [x] Tests pass (`cd backend && bundle exec rails test`)
- [x] `DEVLOG.md` updated
- [ ] Feature branch pushed; PR ready (hand off to owner)
