# P0-005 — Observability & tracing setup

**Priority:** P0  
**Estimate:** 0.5 hours  
**Phase:** 0 — Foundation & Setup  
**PRD reference:** `PRD - AI-Powered Onboarding Assistant.md` §6 (P0-005 ticket)

---

## Goal

Integrate **LangSmith** or **Langfuse** so every LLM call is visible in an observability dashboard. Instrument **LLM::ChatService** to log each API call with: input tokens, output tokens, latency, tool calls (if any), model version, session ID, and trace ID. Traces must be linkable to **OnboardingSession** IDs for debugging.

This ticket does **not** add evals, cost dashboards, or custom analytics — focus is: choose one provider, wire the SDK, and ensure each `chat` invocation produces a trace with the required metadata.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P0-005 |
|--------|----------------------|
| **P0-003** | LLM::ChatService exists and performs real or stubbed OpenAI calls to instrument |

P0-004 is not a blocker. P1-001 (streaming) is not required — non-streaming calls are traced the same way.

---

## Deliverables Checklist

- [ ] **Pick provider** — LangSmith or Langfuse; add gem/HTTP client and env vars (e.g. `LANGSMITH_API_KEY` or `LANGFUSE_SECRET_KEY`, `LANGFUSE_PUBLIC_KEY`)
- [ ] **Instrument LLM::ChatService** — wrap or decorate `chat(messages:)` so that each call: starts a trace/span, records input message count or token estimate, calls OpenAI, records latency, then records output (token usage from response `usage`, tool_calls from `message`, model name)
- [ ] **Attach metadata** — include in each trace: `model`, `session_id` (OnboardingSession ID when available; optional `nil` for anonymous), `trace_id` (provider-generated or UUID), and optionally `user_id` when present
- [ ] **Token and latency** — use OpenAI response `usage` (input_tokens, output_tokens) when present; measure latency from before `create` to after response
- [ ] **.env.example** — document the new API key / endpoint env vars for the chosen provider
- [ ] **Verification** — at least one real or test LLM call produces a trace visible in the provider dashboard with full trace and required fields

---

## Acceptance Criteria (from PRD)

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | Every LLM call appears in the observability dashboard with full trace | Send a chat message; open dashboard; find the corresponding trace |
| 2 | Token counts and latency are captured per request | Trace shows input/output tokens and duration |
| 3 | Traces are linked to OnboardingSession IDs for debugging | When session_id is passed (or set from request), trace metadata includes it; filter by session in dashboard if supported |

---

## Technical Notes

- **LangSmith:** LangChain’s tracing platform; supports OpenAI and custom runs. Ruby: check for `langsmith` gem or use REST API to create runs. Env: `LANGSMITH_API_KEY`, optional `LANGCHAIN_TRACING_V2=true`, `LANGCHAIN_ENDPOINT`.
- **Langfuse:** Open-source observability for LLM apps; supports OpenAI. Ruby: `langfuse` gem or HTTP. Env: `LANGFUSE_SECRET_KEY`, `LANGFUSE_PUBLIC_KEY`, optional `LANGFUSE_HOST`.
- **Where to instrument:** In `LLM::ChatService#chat`, before calling `@client.chat.completions.create`: generate or get trace_id, start span, record start time. After the call: read `response.usage` (or equivalent) for tokens, record latency, log tool_calls from `response.dig("choices", 0, "message", "tool_calls")`, then end span. If the provider’s Ruby SDK expects a different pattern (e.g. callback or decorator), follow its docs.
- **Session ID:** ChatService may not have access to `onboarding_session_id` today. Options: (1) add an optional kwarg `chat(messages:, session_id: nil, trace_metadata: {})` and have the controller (or future job) pass it; (2) set it from `Current` or request context in a wrapper. For P0-005, passing `session_id` when available is enough; full request-scoped context can be refined in P1-001/P1-002.
- **No API key:** If the provider’s env vars are missing, tracing should be a no-op (no exception, no network call) so tests and dev without keys still pass.
- **Tests:** Prefer not to depend on a real provider in CI. Use a stub or conditional: only send traces when the relevant API key is set; otherwise skip or use a null implementation.

---

## Files You Will Likely Create / Modify

| Area | Path | Action |
|------|------|--------|
| Env | `backend/.env.example` | Add provider API key and optional endpoint vars |
| Gemfile | `backend/Gemfile` | Add provider gem (if any) or use `faraday`/`net-http` for REST |
| ChatService | `app/services/llm/chat_service.rb` | Wrap `chat` with tracing: start span, call API, record usage + latency + tool_calls + model, end span |
| Optional | `app/services/observability/tracer.rb` or `app/services/llm/trace_wrapper.rb` | Thin wrapper that forwards to LangSmith/Langfuse; keeps ChatService focused |
| Docs | `docs/tickets/DEVLOG.md` | Update with P0-005 entry and chosen provider |

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All 3 acceptance criteria verified (manual: trigger LLM call, confirm trace in dashboard with tokens, latency, and session_id when passed)
- [ ] Missing provider keys do not break the app or tests
- [ ] `DEVLOG.md` updated with P0-005 entry
- [ ] Feature branch pushed; PR ready for review

---

## Suggested Branch

```bash
git switch -c feature/P0-005-observability-tracing
```

---

## Out of Scope for P0-005

- Eval runs or dataset tracking (later phase)
- Custom cost/analytics dashboard
- Tracing for non-LLM calls (e.g. OCR, booking) — can be added later with same provider
- OpenTelemetry or other backends; stick to one of LangSmith or Langfuse for this ticket

Focus: **one observability provider, ChatService instrumented, every LLM call visible and linkable to OnboardingSession**.
