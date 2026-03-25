---
name: agent-design
description: LLM, prompt, and tool-call design guardrails. Invoke when modifying AI-related code.
---

# Agent / LLM Design — Advisory

This skill reviews AI-related code for safety, correctness, and adherence to the project's agent design principles. It flags risks and improvements but does not rewrite code.

## When to Invoke

When working on code that touches LLM calls, prompts, tool definitions, or conversation state handling.

## Applies To

Files in these paths (and their tests):
- `backend/app/services/llm/` — ChatService, ContextBuilder
- `backend/app/services/tools/` — Router, SchemaValidator
- `backend/app/channels/` — OnboardingChatChannel
- `backend/config/prompts/` — tool_definitions.yml, system prompts

Does NOT apply to non-AI code. Do not invoke for general Rails work.

## Checks

### 1. Prompt Review

- System prompts must define: role, boundaries, available tools.
- Flag prompts that are open-ended without scope constraints.
- Flag prompts that expose internal system details to the model.
- Flag missing system prompts (messages array without a system message).

### 2. Tool Schema Review

- Validate that `config/prompts/tool_definitions.yml` follows conventions:
  - One tool per logical action
  - Clear, unambiguous names
  - All required parameters documented
- Flag tools with overlapping purpose or ambiguous schemas.

### 3. State Handling

- Session state is authoritative — the backend DB is the source of truth.
- Flag any pattern where the LLM's response is trusted to set state directly without going through application code.
- Example violation: trusting "the user confirmed their booking" from the LLM without calling the scheduling module.
- Turn flow must be: user message → (optional) tool calls → update state via code → generate reply.

### 4. Structured Output Validation

- When LLM responses are parsed for intents, fields, or decisions, verify:
  - There is validation of the parsed output format
  - There is a fallback path when output doesn't match expected format
  - Low-confidence or unparseable results are handled explicitly

### 5. Context Window

- Review what's sent in the messages array.
- Flag unbounded history (all messages without truncation/summarization for long sessions).
- Flag missing system prompts.
- Flag unnecessary data being stuffed into context (e.g., full document text when only fields are needed).

## Output Format

```
RISK         path/to/file.rb:line — description (could cause bad behavior)
IMPROVEMENT  path/to/file.rb:line — description (would make system more robust)
OK           path/to/file.rb — passes all checks
```

## Does NOT

- Rewrite prompts or code
- Evaluate prompt quality, tone, or style (that belongs in evals — P5)
- Apply outside AI-related code paths
