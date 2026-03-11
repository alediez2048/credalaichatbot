# P0-004 — Prompt management system

**Priority:** P0  
**Estimate:** 0.5 hours  
**Phase:** 0 — Foundation & Setup  
**PRD reference:** `PRD - AI-Powered Onboarding Assistant.md` §6 (P0-004 ticket)

---

## Goal

Put all LLM-facing text in **version-controlled YAML** under `config/prompts/` and add a **PromptLoader** so the app loads prompts from config instead of hardcoding them. The system prompt must load from YAML and be injected into every LLM call. Changing a prompt file must not require a code change — only a deploy (or reload in dev).

This ticket does **not** add database-backed versioning or feature flags; file-based YAML with optional `version` or `name` keys is enough. Tool definitions already live in `config/prompts/tool_definitions.yml` (P0-003); P0-004 adds the **system prompt** (and optionally emotional support templates / document schemas) and the **loader** that version-tracks which prompt content is active.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P0-004 |
|--------|----------------------|
| **P0-003** | LLM::ContextBuilder and config/prompts/ exist; system prompt is today passed as a string from callers |

P0-001 is required (Rails app). P1-000, P1-001 are not blockers — prompt loading is backend-only.

---

## Deliverables Checklist

- [ ] **System prompt in YAML** — e.g. `config/prompts/system_prompt.yml` (or `config/prompts/onboarding_system.yml`) with at least `content` and optional `version` / `name`
- [ ] **PromptLoader service** — loads a prompt by key (e.g. `"system"`, `"onboarding_system"`); returns `{ content:, version: }` or equivalent; reads from `config/prompts/`; caches in memory in production if desired
- [ ] **Wire system prompt into the pipeline** — wherever `ContextBuilder.build(system_prompt: ...)` is called (tests, future chat controller), obtain the system prompt via PromptLoader instead of an inline string
- [ ] **No prompt strings hardcoded in Ruby** for the default onboarding system prompt — only in YAML
- [ ] (Optional for 0.5 h) Placeholder YAML files for emotional support templates and document type schemas, or a short comment in the primer / README that they will live under `config/prompts/` when added in P2/P3

---

## Acceptance Criteria (from PRD)

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | System prompt loads from YAML and is injected into every LLM call | Integration or unit test: PromptLoader.load("system") returns content; ContextBuilder receives it from loader |
| 2 | Prompts are version-controlled in git (not hardcoded in Ruby) | System prompt text lives only in config/prompts/*.yml |
| 3 | Changing a prompt file does not require a code change | Edit YAML, restart or reload; next LLM call uses new content (no Ruby edit) |

---

## Technical Notes

- **Existing layout:** `config/prompts/tool_definitions.yml` already exists (P0-003). Add e.g. `config/prompts/system_prompt.yml` with structure such as:
  ```yaml
  name: onboarding_system
  version: "1.0"
  content: |
    You are an onboarding assistant. Guide the user through...
  ```
- **PromptLoader:** API can be `PromptLoader.load(key)` → returns string content (or hash with `:content`, `:version`). Key maps to filename (e.g. `"system"` → `system_prompt.yml` or `onboarding_system.yml`). Use `Rails.root.join("config", "prompts", "#{key}.yml")` or a small registry (key → filename).
- **Version-tracking:** For 0.5 h, “version-tracks which prompts are active” can mean: (1) YAML has a `version` key and PromptLoader returns it so callers can log it or send to tracing (P0-005), or (2) a simple in-memory cache keyed by file mtime or version. No DB or feature-flag service required.
- **ContextBuilder:** Keep `ContextBuilder.build(system_prompt:, history:, current_message:)` as-is. Callers (e.g. a future OnboardingChatController or test) will do `system_prompt = PromptLoader.load("system")` (or `load("onboarding_system")`) and pass it in. That way prompt content stays out of the context builder and is the caller’s responsibility.
- **Emotional support / document schemas:** If time allows, add `config/prompts/emotional_support.yml` and/or `config/prompts/document_types/` with one stub file; otherwise document in DEVLOG that these will be added when implementing P2/P3.

---

## Files You Will Likely Create / Modify

| Area | Path | Action |
|------|------|--------|
| System prompt | `config/prompts/system_prompt.yml` or `onboarding_system.yml` | Create — name, version, content |
| Loader | `app/services/prompt_loader.rb` or `app/services/llm/prompt_loader.rb` | Create — load by key, return content (and optional version) |
| Call sites | Tests / future controller | Modify — use PromptLoader for system prompt instead of inline string |
| Docs | `docs/tickets/DEVLOG.md` | Update with P0-004 entry |

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All 3 acceptance criteria verified (test or manual: change YAML, reload, next request uses new prompt)
- [ ] System prompt only in YAML; PromptLoader used by any code that builds context for the LLM
- [ ] `DEVLOG.md` updated with P0-004 entry
- [ ] Feature branch pushed; PR ready for review

---

## Suggested Branch

```bash
git switch -c feature/P0-004-prompt-management
```

---

## Out of Scope for P0-004

- Database or external store for prompt versions
- Feature flags / A-B testing of prompts (e.g. Flipper)
- Evals or CI that run on prompt changes (later phase)
- Full emotional support or document-type prompt content (P2/P3); stubs or placeholders only if time allows

Focus: **system prompt in YAML + PromptLoader + wire into LLM pipeline**. No code change required when editing prompt text.
