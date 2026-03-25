# P1-002 — Conversational onboarding flow with state management

**Priority:** P1
**Estimate:** 4 hours
**Phase:** 1 — AI Chatbot Core (MVP GATE)
**Status:** In progress

---

## Goal

Build the orchestration layer that turns the chat into a guided onboarding flow. The assistant walks users through steps (welcome → personal info → document upload → scheduling → review → complete), manages state transitions via `OnboardingSession`, executes tool calls server-side, and streams the final response to the client. Steps that depend on future phases (OCR, scheduling, sentiment) return friendly "coming soon" messages while the flow works end-to-end.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P1-002 |
|--------|----------------------|
| **P0-003** | `LLM::ChatService`, `Tools::Router`, `Tools::SchemaValidator`, 9 tool definitions |
| **P1-001** | Chat UI + Action Cable streaming + message persistence |

---

## Onboarding Steps

```
welcome → personal_info → document_upload → scheduling → review → complete
```

| Step | What happens | Tools used |
|------|-------------|-----------|
| `welcome` | Greet user, explain the process | `startOnboarding` |
| `personal_info` | Collect name, email, phone, DOB conversationally | `saveOnboardingProgress` |
| `document_upload` | Explain what documents are needed | `extractDocumentData` (stub → "coming soon") |
| `scheduling` | Offer to book appointment | `getAvailableSlots`, `bookAppointment` (stubs → "coming soon") |
| `review` | Summarize collected data, ask for confirmation | `getOnboardingState` |
| `complete` | Congratulate, show next steps | `saveOnboardingProgress` (final) |

---

## Deliverables Checklist

- [ ] `config/prompts/onboarding_steps.yml` — step definitions (name, description, required_fields, prompt_instructions, next_step)
- [ ] `Onboarding::Orchestrator` — processes user messages with step-aware context, handles tool calls, advances state
- [ ] Real tool handlers for `startOnboarding`, `saveOnboardingProgress`, `getOnboardingState`
- [ ] Step-aware system prompt built from YAML config + session state
- [ ] `OnboardingChatChannel` updated to use Orchestrator instead of plain streaming
- [ ] `OnboardingSession` state management: `current_step`, `progress_percent`, `metadata` updated on each turn
- [ ] Unit tests for Orchestrator (mock LLM, verify step transitions, tool call handling)
- [ ] Unit tests for step definitions loading from YAML
- [ ] Integration test: multi-turn conversation advancing through steps

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | Chat starts at `welcome` step and greets user | Send first message → assistant introduces onboarding |
| 2 | Assistant collects personal info conversationally | Provide name, email, phone → data saved to session metadata |
| 3 | Steps advance automatically when required fields are collected | After personal_info complete → moves to document_upload |
| 4 | Stub steps show "coming soon" gracefully | Document upload and scheduling steps acknowledge and move on |
| 5 | Session state persists across page reload | Reload → chat history loads, current step preserved |
| 6 | Tool calls execute server-side and results feed back to LLM | Observe via logs or traces that tools are called and results returned |

---

## Architecture

### New files

| File | Purpose |
|------|---------|
| `app/services/onboarding/orchestrator.rb` | Main orchestration: step-aware prompting, tool call loop, state advancement |
| `config/prompts/onboarding_steps.yml` | Declarative step definitions |

### Modified files

| File | Changes |
|------|---------|
| `app/channels/onboarding_chat_channel.rb` | Use Orchestrator instead of plain ChatService streaming |
| `app/services/tools/router.rb` | Replace 3 stub handlers with real implementations |
| `app/services/llm/chat_service.rb` | No changes expected (uses existing `#chat` with tools) |

### Flow

1. User sends message via Action Cable
2. Channel persists user message, calls `Onboarding::Orchestrator.process(session, message)`
3. Orchestrator builds step-aware system prompt (role + step instructions + collected data + available tools)
4. Calls `LLM::ChatService#chat` (non-streaming, with tools)
5. If LLM returns tool_calls → executes via `Tools::Router` → appends results → calls LLM again for final response
6. Orchestrator updates session state (current_step, progress_percent, metadata)
7. Channel broadcasts final assistant text to client (streamed or complete)
8. Assistant message persisted

### System prompt structure

```
You are Credal's onboarding assistant. Guide the user through employee onboarding step by step.

CURRENT STEP: {step_name}
STEP INSTRUCTIONS: {from YAML}
DATA COLLECTED SO FAR: {from session metadata}
AVAILABLE ACTIONS: {tool names relevant to this step}

Rules:
- Stay on the current step. Do not skip ahead.
- When you have all required fields for this step, call saveOnboardingProgress.
- Be conversational and warm. Collect one piece of info at a time.
- If a feature is not yet available, acknowledge it warmly and move to the next step.
```

### Tool handler implementations

| Tool | Implementation |
|------|---------------|
| `startOnboarding` | Sets `current_step: "welcome"`, returns session info |
| `saveOnboardingProgress` | Persists fields to `OnboardingSession#metadata`, advances step if required fields complete |
| `getOnboardingState` | Returns current step + collected data from session metadata |
| Other 6 tools | Remain stubs with "coming soon" responses |

---

## Files You Should READ Before Coding

1. `app/services/llm/chat_service.rb` — `#chat` method with tool calling
2. `app/services/tools/router.rb` — stub handler pattern
3. `app/channels/onboarding_chat_channel.rb` — current streaming flow
4. `app/services/llm/context_builder.rb` — message array construction
5. `config/prompts/tool_definitions.yml` — 9 tool schemas
6. `db/schema.rb` — OnboardingSession columns (current_step, progress_percent, metadata)

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All acceptance criteria verified
- [ ] `DEVLOG.md` updated with P1-002 entry
- [ ] Feature branch pushed; PR ready for review

---

## Suggested Branch

```bash
git switch -c feature/P1-002-onboarding-orchestration
```

---

## Out of Scope for P1-002

- Real document upload/OCR (P2)
- Real scheduling/booking (P3)
- Sentiment analysis (P4)
- Session resumption UX (P1-003) — but state is persisted so P1-003 just loads it
- Error handling beyond basic try/rescue (P1-004)
