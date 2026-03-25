# P1-004 — Error handling & graceful fallbacks

**Priority:** P1
**Estimate:** 2 hours
**Phase:** 1 — AI Chatbot Core (MVP GATE)
**Status:** In progress

---

## Goal

When the LLM times out, the API key is missing, a tool call fails, or any unexpected error occurs, the user sees a helpful message and can retry — not a blank screen or cryptic error.

---

## Deliverables Checklist

- [ ] `Onboarding::ErrorHandler` service with categorized error responses
- [ ] Orchestrator wraps LLM calls with timeout and retry (1 retry, 30s timeout)
- [ ] Tool call failures return graceful messages instead of crashing the flow
- [ ] Channel sends structured error broadcasts with retry hint
- [ ] React UI shows error messages with a retry button
- [ ] Missing API key shows a clear message (not a crash)
- [ ] Unit tests for error categorization and fallback paths
