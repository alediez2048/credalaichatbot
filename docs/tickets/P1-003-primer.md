# P1-003 — Session persistence & resumption

**Priority:** P1
**Estimate:** 2 hours
**Phase:** 1 — AI Chatbot Core (MVP GATE)
**Status:** In progress

---

## Goal

When a user returns to `/onboarding` with an existing session, the chat loads their history, shows their progress, and the assistant acknowledges where they left off. Completed sessions show a completion state. The React UI displays a progress bar and current step indicator.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P1-003 |
|--------|----------------------|
| **P1-002** | Orchestrator manages current_step, progress_percent, metadata |

---

## Deliverables Checklist

- [ ] Controller passes `current_step` and `progress_percent` to the view
- [ ] React UI shows progress bar and current step name
- [ ] Returning user with in-progress session sees welcome-back message from assistant
- [ ] Completed sessions show completion state (not a new chat)
- [ ] Orchestrator summarizes prior context for long sessions (>20 messages)
- [ ] User can reset their session (start over button)
- [ ] Unit tests for resumption logic and context summarization

---

## Out of Scope

- Anonymous-to-authenticated session merge (P1-005)
- Session expiration/TTL
