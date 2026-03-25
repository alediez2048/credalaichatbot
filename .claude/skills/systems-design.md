---
name: systems-design
description: Module boundary and architecture adherence checks. Invoke before changes that cross module boundaries or add services.
---

# Systems Design Adherence — Advisory

This skill flags architectural issues. You may override findings with justification, but you must acknowledge them.

## When to Invoke

Before implementing changes that cross module boundaries, add new services, or modify data flow between components.

## Module Boundaries

The project has these module boundaries (discover additional modules from `backend/app/services/` directory structure):

| Module | Responsibility | Key paths |
|--------|---------------|-----------|
| **Chat / conversation** | Turns, history, session state. Calls orchestration. | `app/channels/`, `app/javascript/components/` |
| **Onboarding orchestration** | Step sequencing, delegation to domain modules. | `app/services/onboarding/` |
| **Document / OCR** | Upload, extraction, validation, confidence. | `app/services/documents/` |
| **Scheduling** | Availability, booking, rescheduling. | `app/services/scheduling/` |
| **Emotional support** | Content selection by step/state. | `app/services/support/` |
| **Auth** | Login, signup, session identity. | Devise, `app/models/user.rb` |
| **LLM** | OpenAI adapter, context building, tools. | `app/services/llm/`, `app/services/tools/` |
| **Observability** | Tracing, logging. | `app/services/observability/` |

**Update this list in the skill file when new modules are introduced.**

## Checks

### 1. Dependency Direction

Data flows one way: orchestration → domain modules. Domain modules do NOT call orchestration or each other.

- Scan `require`, `include`, and class references in changed files.
- Flag any reverse dependency (e.g., scheduling importing from chat, OCR importing from scheduling).

### 2. Interface Contracts

- Cross-module calls should use typed request/response patterns with explicit error handling.
- Flag raw hash passing between modules without documented structure.
- Flag untyped exceptions leaking across module boundaries.

### 3. State Ownership

- Each piece of state has one owner (one DB table, one service).
- Flag duplicate state across frontend and backend that can diverge.
- Flag modules storing state that belongs to another module.

### 4. External Service Boundaries

- LLM, OCR, and calendar API calls must go through adapter modules (`app/services/llm/`, etc.).
- Flag direct API calls from controllers, channels, or business logic.

## Output Format

```
VIOLATION  path/to/file.rb:14 — description of architectural violation
DRIFT      path/to/file.rb:28 — not broken yet but heading that direction
OK         path/to/file.rb — passes all checks
```

## Does NOT

- Refactor code — only diagnoses issues
- Enforce naming conventions or code style
- Apply to changes within a single module (intra-module structure is the developer's call)
