# P0-003 — AI service layer & tool calling infrastructure

**Priority:** P0  
**Estimate:** 1.5 hours  
**Phase:** 0 — Foundation & Setup  
**PRD reference:** `PRD - AI-Powered Onboarding Assistant.md` §5 (Architecture, Tool Calling), §6 (P0-003 ticket)

---

## Goal

Build the backend plumbing so the LLM can receive user messages and respond with **function (tool) calls**. Implement **Tools::Router**, **Tools::SchemaValidator**, **LLM::ChatService**, and **LLM::ContextBuilder**. Define all **9 tool schemas** in YAML. Wire the **OpenAI API** with function calling so a chat message can trigger a tool call, the router executes it, and the result is returned to the LLM.

This ticket does **not** implement full business logic for each tool — stubs or minimal implementations are enough. The focus is: tool definitions load from config, the router maps names to callables, the validator rejects bad params, and ChatService can send a message and receive a tool call response.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P0-003 |
|--------|----------------------|
| **P0-001** | Rails app, DB, `OnboardingSession`, `Message` (and other models) must exist |

P0-002 and P1-000 are **not** blockers — the AI layer is backend-only. P0-004 (prompt management) can be done after or in parallel; for P0-003 the system prompt can be a small inline string or loaded from a single YAML file.

---

## The 9 tools (from PRD §5.3)

| Tool | Type | Purpose |
|------|------|---------|
| `startOnboarding` | Write | Initialize a new onboarding session (userId, sessionId) |
| `extractDocumentData` | Write | Process uploaded document via OCR (imageFile, documentType) |
| `validateExtractedData` | Read | Check extracted fields against schema |
| `getAvailableSlots` | Read | Fetch available appointment slots (dateRange, serviceType) |
| `bookAppointment` | Write | Book an appointment (userId, slotId, serviceType) |
| `detectUserSentiment` | Read | Analyze emotional state from message history |
| `getSupportContent` | Read | Retrieve emotional support content (context, sentimentLevel) |
| `saveOnboardingProgress` | Write | Persist current form state (userId, step, data) |
| `getOnboardingState` | Read | Load saved progress for session resumption (userId) |

Write operations require user confirmation before execution (can be enforced in a later ticket). All tool calls go through **SchemaValidator** then **Router**.

---

## Deliverables Checklist

- [ ] `config/prompts/tool_definitions.yml` — all 9 tools with name, description, parameters (OpenAI function-call schema shape)
- [ ] **Tools::SchemaValidator** — validates tool name and parameters against definitions; returns structured error when invalid
- [ ] **Tools::Router** — maps tool name (string) to a service object or callable; invokes it with validated params and returns result
- [ ] **LLM::ContextBuilder** — builds the messages array (e.g. system + conversation history + current user message); injects system prompt (can be stub or from YAML)
- [ ] **LLM::ChatService** — sends messages to OpenAI with tool definitions; returns raw API response (including tool_calls when present)
- [ ] Wire OpenAI client (e.g. `openai` gem or `httpx`) with function calling; pass tool definitions from YAML
- [ ] Integration test: send a chat message that triggers a tool call (e.g. `getOnboardingState`), execute via router, return result to caller

---

## Acceptance Criteria (from PRD)

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | Tools::Router maps function names to service objects | Unit test: router.call("getOnboardingState", { user_id: 1 }) → delegates to correct handler |
| 2 | SchemaValidator rejects invalid tool call parameters with structured errors | Unit test: invalid params → raises or returns error hash with message/field |
| 3 | LLM::ChatService sends a message and receives a function call response | Integration test or script: send message, get back response with tool_calls |
| 4 | Tool definitions load from config/prompts/tool_definitions.yml | Load YAML in test; assert 9 tools and expected keys (name, parameters) |
| 5 | Integration test: send chat message → tool call → execute → return result | Full path: ChatService → tool_calls in response → Router → result returned |

---

## Technical Notes

- **Service location:** Put services under `app/services/` (e.g. `app/services/llm/chat_service.rb`, `app/services/tools/router.rb`) so they autoload. Alternatively `lib/` if you prefer; ensure eager load in production if needed.
- **OpenAI:** Use the `openai` gem (or REST) with `response_format: { type: "json_object" }` only if needed; for tool calling, pass `tools: tool_definitions` and handle `response.dig("choices", 0, "message", "tool_calls")`. Model: `gpt-4o` or configurable via `ENV["OPENAI_MODEL"]`.
- **YAML shape:** Match OpenAI function-calling schema: each tool has `name`, `description`, `parameters` (JSON Schema: type, properties, required). Example:
  ```yaml
  - name: getOnboardingState
    description: Load saved onboarding progress for the user
    parameters:
      type: object
      properties:
        user_id: { type: "string", description: "User or session identifier" }
      required: [user_id]
  ```
- **Stub implementations:** For P0-003, each tool handler can return a hash like `{ success: true, data: {} }` or `{ error: "Not implemented" }`. Full behavior (DB, OCR, etc.) comes in P1-002, P2-001, etc.
- **ContextBuilder:** Inputs: system prompt (string), array of prior messages (e.g. from `Message`), current user message. Output: array of hashes for OpenAI API (e.g. `[{ role: "system", content: "..." }, ...]`).

---

## Files You Will Likely Create / Modify

| Area | Path | Action |
|------|------|--------|
| Tool definitions | `config/prompts/tool_definitions.yml` | Create — 9 tools, OpenAI-compatible schema |
| Router | `app/services/tools/router.rb` | Create — map name → callable, call with params |
| Validator | `app/services/tools/schema_validator.rb` | Create — validate name + params against YAML |
| Chat service | `app/services/llm/chat_service.rb` | Create — OpenAI client, send messages, return response |
| Context builder | `app/services/llm/context_builder.rb` | Create — build messages array from system + history + current |
| Tool handlers | `app/services/tools/handlers/` or inline in Router | Create — one stub per tool (or single stub that handles all) |
| Integration test | `test/integration/llm_tool_calling_test.rb` or `spec/` | Create — send message, assert tool call, execute, result |
| Gemfile | `Gemfile` | Add `openai` gem (or use Net::HTTP/httpx) |
| Env | `.env.example` | Add `OPENAI_API_KEY`, `OPENAI_MODEL` |

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All 5 acceptance criteria verified (unit + integration test or manual script)
- [ ] Tool definitions in YAML; no tool schemas hardcoded in Ruby
- [ ] `DEVLOG.md` updated with P0-003 entry
- [ ] Feature branch pushed; PR ready for review

---

## Suggested Branch

```bash
git switch -c feature/P0-003-llm-tool-calling
```

---

## Out of Scope for P0-003

- Streaming responses (P1-001)
- Real OCR, booking, or sentiment logic (P2, P3, P4)
- Prompt management / versioning (P0-004)
- Observability / tracing (P0-005)
- Onboarding orchestration or multi-turn flow logic (P1-002)

Implement the **pipe**: message in → OpenAI with tools → tool_calls out → Router → result. Stub tool behavior is enough.
