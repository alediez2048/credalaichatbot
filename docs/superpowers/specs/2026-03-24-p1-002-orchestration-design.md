# P1-002 — Conversational Onboarding Orchestration Design

**Date:** 2026-03-24
**Status:** Approved
**Ticket:** P1-002

---

## Problem

The chat currently streams plain text from the LLM with no awareness of onboarding steps, tool calling, or state management. Users get a general-purpose chatbot instead of a guided onboarding flow.

## Solution

An `Onboarding::Orchestrator` service that sits between the Action Cable channel and the LLM. It builds step-aware prompts, handles tool call loops, persists collected data, and advances the onboarding state machine. Steps that depend on unbuilt features (OCR, scheduling) return graceful "coming soon" messages.

---

## Onboarding Steps

Defined in `config/prompts/onboarding_steps.yml`:

```yaml
steps:
  - name: welcome
    description: Greet the user and explain the onboarding process
    required_fields: []
    prompt_instructions: |
      Welcome the user warmly. Explain that you'll guide them through onboarding:
      collecting some personal information, uploading documents, and scheduling
      an orientation appointment. Ask if they're ready to begin.
    tools: [startOnboarding]
    next_step: personal_info

  - name: personal_info
    description: Collect the user's personal information
    required_fields: [full_name, email, phone, date_of_birth]
    prompt_instructions: |
      Collect the user's personal information one field at a time. Be conversational.
      Required: full name, email address, phone number, and date of birth.
      When you have a piece of information, call saveOnboardingProgress to store it.
      When all required fields are collected, confirm with the user and move on.
    tools: [saveOnboardingProgress, getOnboardingState]
    next_step: document_upload

  - name: document_upload
    description: Request identity documents
    required_fields: []
    prompt_instructions: |
      Explain that document upload (driver's license, W-4, etc.) will be available soon.
      For now, acknowledge this step warmly and let the user know you'll move to scheduling.
      Do not ask them to upload anything.
    tools: []
    next_step: scheduling

  - name: scheduling
    description: Schedule an orientation appointment
    required_fields: []
    prompt_instructions: |
      Explain that appointment scheduling will be available soon.
      For now, acknowledge this step warmly and move to the review step.
    tools: []
    next_step: review

  - name: review
    description: Review all collected information
    required_fields: []
    prompt_instructions: |
      Summarize all the information collected so far. Present it clearly and ask
      the user to confirm everything looks correct. Use getOnboardingState to
      retrieve the data if needed.
    tools: [getOnboardingState]
    next_step: complete

  - name: complete
    description: Onboarding complete
    required_fields: []
    prompt_instructions: |
      Congratulate the user on completing onboarding. Let them know what happens
      next (HR will review, they'll receive a welcome email, etc.). Be warm and encouraging.
    tools: [saveOnboardingProgress]
    next_step: null
```

---

## Onboarding::Orchestrator

**Location:** `app/services/onboarding/orchestrator.rb`

**Interface:**
```ruby
Onboarding::Orchestrator.new(session).process(user_message)
# => { content: "Hello! Welcome to...", step_changed: false }
```

**Responsibilities:**

1. Load current step definition from YAML
2. Build system prompt: base role + step instructions + collected data + available tools
3. Build messages array: system prompt + conversation history + user message
4. Call `LLM::ChatService#chat` with tools enabled (only tools for current step)
5. Tool call loop (max 3 iterations):
   - If response has `tool_calls` → execute each via `Tools::Router`
   - Append tool results as `role: "tool"` messages
   - Call LLM again with updated messages
   - Repeat until LLM returns plain text or max iterations hit
6. After final response: check if step should advance (required fields collected)
7. Update `OnboardingSession`: `current_step`, `progress_percent`, `metadata`
8. Return final assistant content

**Step advancement logic:**
- Step has `required_fields: []` → advance after first exchange (welcome, document_upload, scheduling)
- Step has required fields → advance when all fields present in `session.metadata`
- `complete` step → no advancement (terminal)
- Advancement triggered by the orchestrator after the LLM response, not by the LLM itself

**Progress calculation:**
```ruby
STEPS = %w[welcome personal_info document_upload scheduling review complete]
progress = ((STEPS.index(current_step) + 1).to_f / STEPS.size * 100).round
```

---

## Tool Handler Implementations

### `startOnboarding`
```ruby
def call(args, session:)
  session.update!(current_step: "welcome") if session.current_step.blank?
  { success: true, data: { session_id: session.id, current_step: session.current_step } }
end
```

### `saveOnboardingProgress`
```ruby
def call(args, session:)
  step = args["step"] || session.current_step
  data = args["data"] || {}
  merged = (session.metadata || {}).merge(data)
  session.update!(metadata: merged)
  { success: true, data: { step: step, saved_fields: data.keys } }
end
```

### `getOnboardingState`
```ruby
def call(args, session:)
  { success: true, data: {
    current_step: session.current_step,
    progress_percent: session.progress_percent,
    collected_data: session.metadata
  }}
end
```

### Router changes

Tool handlers need access to the `OnboardingSession`. The Router's `call` method gains an optional `context:` keyword:

```ruby
def call(tool_name, arguments, context: {})
  # ... validation ...
  handler.call(args, **context)
end
```

Stub handlers ignore the context. Real handlers use `session:` from it.

---

## Channel Integration

`OnboardingChatChannel#send_message` changes from:

```
persist user message → build context → stream_chat → persist assistant message
```

to:

```
persist user message → Orchestrator.process(session, body) → broadcast response → persist assistant message
```

The orchestrator returns complete text (tool calls happen internally). The channel broadcasts it as a complete message or re-streams it token by token. For simplicity in P1-002, broadcast the complete response. Streaming the orchestrated response can be optimized later.

---

## System Prompt Template

```
You are Credal's AI onboarding assistant. You guide new employees through the onboarding process step by step.

## Current Step: {step_name}
{step_instructions}

## Data Collected So Far
{json of session.metadata, or "No data collected yet."}

## Rules
- Stay focused on the current step. Do not skip ahead or go back.
- Be conversational, warm, and professional.
- Collect information one piece at a time — don't overwhelm the user.
- When you have the information needed, use the appropriate tool to save it.
- If a feature is coming soon, acknowledge it gracefully and move forward.
- Keep responses concise — 2-3 sentences unless more detail is needed.
```

---

## Testing

### Unit: Orchestrator
- Mock `LLM::ChatService#chat` to return predetermined responses
- Test: welcome step → returns greeting, no step change
- Test: personal_info step with all fields → advances to document_upload
- Test: tool call loop → orchestrator executes tool and re-calls LLM
- Test: max tool call iterations respected

### Unit: Step definitions
- Test: YAML loads all 6 steps
- Test: each step has required keys (name, prompt_instructions, next_step)
- Test: required_fields present for personal_info

### Unit: Real tool handlers
- Test: `startOnboarding` sets current_step
- Test: `saveOnboardingProgress` merges data into metadata
- Test: `getOnboardingState` returns session state

### Integration
- Multi-turn conversation mock: welcome → collect name → collect email → etc.
- Verify session.current_step advances
- Verify session.metadata accumulates fields
