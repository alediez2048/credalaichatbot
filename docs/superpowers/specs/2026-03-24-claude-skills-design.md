# Claude Code Skills — Design Spec

**Date:** 2026-03-24
**Status:** Approved
**Scope:** 8 Claude Code skills + CLAUDE.md integration for the Credal.ai onboarding assistant project

---

## Problem

Development workflow discipline (TDD, source control, scope control, systems design adherence, documentation) is currently codified only in `.cursor/rules/*.mdc`. The developer uses both Cursor and Claude Code. Without equivalent enforcement in Claude Code, workflow standards drift depending on which tool is active.

## Solution

8 standalone Claude Code skills in `.claude/skills/`, each mirroring and expanding on one cursor rule. A `CLAUDE.md` at the project root wires them into a ticket lifecycle so Claude Code follows the workflow naturally every session.

No hooks. Enforcement through CLAUDE.md convention + hard gates in skill definitions.

---

## Skill Inventory

| # | Skill | File | Slash Command | Enforcement | Mirrors Cursor Rule |
|---|-------|------|---------------|-------------|---------------------|
| 1 | TDD | `tdd.md` | `/tdd` | Hard gate | `tdd.mdc` |
| 2 | Source Control | `source-control.md` | `/source-control` | Hard gate | `git-workflow.mdc` |
| 3 | Verify Before Done | `verify-before-done.md` | `/verify` | Hard gate | `verify-before-done.mdc` |
| 4 | Systems Design | `systems-design.md` | `/systems-design` | Advisory | `systems-design.mdc` |
| 5 | Scope Control | `scope-control.md` | `/scope-control` | Advisory | `scope-control.mdc` |
| 6 | Context Loading | `context-loading.md` | `/context-loading` | Advisory | `context-loading.mdc` |
| 7 | Documentation | `documentation.md` | `/docs` | Advisory | *(new — no cursor rule equivalent)* |
| 8 | Agent/LLM Design | `agent-design.md` | `/agent-design` | Advisory | `agent-design.mdc` |

**Hard gate** = Claude will refuse to proceed until conditions are met. Enforcement is via Claude's adherence to skill instructions; there is no pre-tool hook or programmatic block. The user can always override explicitly, but Claude will not skip these steps on its own.
**Advisory** = skill flags issues, recommends fixes, allows override with justification.

**`first-principles.mdc` coverage:** This cursor rule is not a standalone skill. Its concerns are absorbed by existing skills:
- "Contracts over implementation" → `/systems-design` (interface contract review)
- "Graceful degradation" → `/agent-design` (fallback paths) + `/tdd` (error path testing)
- "Depend inward" → `/systems-design` (dependency direction check)
- "Observability by default" → `/agent-design` (context window check, logging)
- "Deliver the checklist, not the ideal" → `/scope-control` (deliverables progress)
- "No speculative code" → `/scope-control` (change classification)

---

## File Structure

```
.claude/
  skills/
    tdd.md
    source-control.md
    systems-design.md
    scope-control.md
    context-loading.md
    verify-before-done.md
    documentation.md
    agent-design.md
CLAUDE.md
```

---

## Skill Specifications

### 1. TDD (`/tdd`) — Hard Gate

**When to invoke:** Before implementing any feature or fix.

**Behavior:**

1. **Assess** — reads the current ticket primer to understand deliverables and acceptance criteria.
2. **Identify test files** — checks existing test structure under `backend/test/` to determine where new tests go. Follows existing naming conventions.
3. **Red phase** — writes test(s) first. Runs `bundle exec rails test <test_file>`. Confirms tests fail for the right reason. Blocks if tests pass (not testing new behavior) or fail for the wrong reason.
   - **Right-reason failures:** Assertion failures where the expected behavior is not yet implemented.
   - **Wrong-reason failures:** Syntax errors, missing requires/imports, unrelated test failures, configuration errors. Fix these before proceeding.
4. **Green phase** — implements minimum code to pass tests. Runs test file again. Blocks until all tests green.
5. **Refactor phase** — only after green. Improves structure without changing behavior. Runs tests again to confirm still green.

**What to test** (reference guidance when the primer lacks specifics):
- **API and service boundaries:** Request/response shapes, status codes, error responses.
- **Business logic:** Validation rules, state transitions, field mapping.
- **Agent/LLM behavior:** Structured outputs, fallback paths when LLM returns invalid JSON.
- **OCR and data extraction:** Fixed sample documents, expected fields, confidence flags.
- **Error and fallback paths:** Timeouts, invalid input, "AI could not parse" flows.

**What NOT to test:**
- Implementation details (internal function names, private state). Test observable behavior.
- Live LLM or external API calls in the main suite. Use mocks/stubs/recorded responses.

**Hard gates:**
- No implementation code until a failing test exists
- No refactoring until tests are green
- No declaring done with any test failing

**Does not:** Run the full suite on every cycle (specific file during red-green, full suite at end).

---

### 2. Source Control (`/source-control`) — Hard Gate

**When to invoke:** Before starting work on a ticket, and before committing/pushing.

**At ticket start:**
1. **Branch check** — verifies not on `main`. If on `main`, creates feature branch: `feature/P?-???-short-name` (e.g., `feature/P1-002-onboarding-orchestration`). Note: this tightens the cursor rule convention (which uses `feature/<description>` without ticket IDs) to improve traceability in this ticket-driven project.
2. **Clean state check** — `git status` to flag uncommitted changes from prior work.

**At commit time:**
3. **Staged file audit** — flags `.env`, `.DS_Store`, credentials, build artifacts, unrelated files.
4. **Commit message format** — enforces Conventional Commits with ticket reference (e.g., `feat(P1-002): add onboarding state machine`).
5. **Small logical commits** — if staged changes span multiple concerns, recommends splitting.

**At push/PR time:**
6. **Branch push** — pushes with `-u origin` if not tracking.
7. **PR creation** — `gh pr create` against `main` with structured title and body.

**Hard gates:**
- No commits to `main`
- No staging forbidden files
- No commits without Conventional Commit format

---

### 3. Verify Before Done (`/verify`) — Hard Gate

**When to invoke:** Before committing, before marking a ticket complete, before opening a PR.

**Behavior:**
1. **Test suite** — runs `bundle exec rails test` from `backend/`. All must pass.
2. **Lint** — runs `bundle exec rubocop` (Ruby) and `npx eslint app/javascript/` (JS) from `backend/`. Reports errors, does not auto-fix. If a linter is not yet configured, skips with a note rather than failing.
3. **Staged file audit** — flags forbidden files and unrelated files. (This intentionally overlaps with `/source-control`'s staged file check as defense-in-depth — `/verify` is the final gate.)
4. **Deliverables checklist** — reads ticket primer checklist, cross-references against diff. Reports each item as done or missing. (This is a final-pass check; `/scope-control` does a similar progress check during implementation. The distinction: `/scope-control` checks mid-flight, `/verify` is the pre-commit gate.)
5. **Acceptance criteria spot-check** — lists ticket's ACs, prompts for manual confirmation where automation isn't possible.

**Hard gates:**
- No commit if tests fail
- No commit if forbidden files staged
- No ticket completion if deliverables have unchecked items

**Output format:**
```
PASS  Tests (47 passed, 0 failed)
PASS  Staged files (no forbidden files)
FAIL  Deliverables: item 3 "Session persistence" — no matching code found
MANUAL  AC #4 "Works on 375px" — confirm manually
```

---

### 4. Systems Design (`/systems-design`) — Advisory

**When to invoke:** Before implementing changes that cross module boundaries, add new services, or modify data flow.

**Behavior:**
1. **Identifies affected modules** — maps changes to the project's module boundaries. Current modules: chat/conversation, onboarding orchestration, document/OCR, scheduling, emotional support, auth. (This list should be updated in the skill file when new modules are introduced. The skill should also discover modules from the `app/services/` directory structure.)
2. **Dependency direction check** — verifies one-way data flow: orchestration → domain modules. Flags reverse dependencies.
3. **Interface contract review** — checks cross-module calls use typed request/response with explicit error handling. Flags raw hash passing, untyped exceptions.
4. **State ownership check** — verifies single source of truth for state. Flags duplicate state across frontend/backend or cross-module.
5. **External service boundary check** — confirms LLM/OCR/calendar calls go through adapter modules.

**Example output:**
```
VIOLATION  app/services/scheduling/slot_service.rb:14 — imports from LLM::ChatService (scheduling must not depend on chat)
DRIFT      app/channels/onboarding_chat_channel.rb:28 — raw hash passed to Tools::Router instead of typed params
OK         app/services/llm/chat_service.rb — calls OpenAI through adapter, state updated via DB
```

Override with "proceed anyway" and a justification.

**Does not:** Refactor code. Enforce naming or style.

---

### 5. Scope Control (`/scope-control`) — Advisory

**When to invoke:** During implementation, especially before editing files outside the ticket's listed scope. Note: this is advisory in Claude Code (flags issues, allows override) even though `scope-control.mdc` uses "MANDATORY" language. Rationale: Claude Code skills cannot prevent file edits, only flag them after the fact. The advisory approach achieves the same goal through awareness rather than blocking.

**Behavior:**
1. **Loads ticket scope** — reads primer's "Deliverables Checklist" and "Files You Will Likely Modify / Create".
2. **Diff audit** — `git diff --name-only` against branch base. Flags files outside scope.
3. **Change classification** — for each flagged file: "necessary dependency", "scope creep", or "accidental".
4. **Deliverables progress** — cross-references implemented work against checklist. Reports done/pending/missing.

**Example output:**
```
SCOPE CREEP  app/services/llm/chat_service.rb — refactored error handling (not in P1-002 deliverables)
NECESSARY    config/routes.rb — added route for new controller (required by deliverable #2)
OK           app/services/onboarding/state_machine.rb — in scope
PROGRESS     [x] Deliverable 1: State machine  [ ] Deliverable 2: Step transitions  [ ] Deliverable 3: Tests
```

**Does not:** Revert changes. Prevent file edits.

---

### 6. Context Loading (`/context-loading`) — Advisory

**When to invoke:** Before starting implementation on any ticket.

**Behavior:**
1. **Reads ticket primer** — loads `docs/tickets/P?-???-primer.md`. Extracts goal, deliverables, ACs, technical notes, files to modify, files to read.
2. **Reads DEVLOG** — loads `docs/tickets/DEVLOG.md` for prior decisions and follow-ups.
3. **Reads dependency primers** — checks the dependency tree in `docs/tickets/README.md` (rendered as an ASCII tree with `├──` and `└──` showing parent→child relationships). "Immediate parent" means the ticket(s) that this ticket directly depends on per the tree (e.g., P1-001 depends on P0-003). Reads those parent primers to understand what's already in place.
4. **Reads source files** — opens files listed in primer's "Files You Will Likely Modify" and "Files You Should READ Before Coding".
5. **Produces context summary** — goal, key prior decisions, existing patterns, relevant follow-ups, unmet blockers.

**Output:** Warns if prerequisites not done in DEVLOG. Flags missing files as expected-to-create vs possibly-missing.

**Does not:** Create branches or write code. Duplicate primer content.

---

### 7. Documentation (`/docs`) — Advisory

**When to invoke:** After completing a ticket's implementation, before or alongside the final commit.

**Behavior:**
1. **DEVLOG entry** — generates draft entry following the template established in existing entries in `docs/tickets/DEVLOG.md` (see "Template" section at top of DEVLOG). Structure: date, branch, "What shipped" (bullet list), "Decisions" (bullet list), "Follow-ups / debt" (bullet list). Derived from git diff and deliverables checklist. Presents for review before writing.
2. **README check** — scans `backend/README.md` for sections needing updates (new env vars, setup steps, tables, commands). Flags specific sections if relevant.
3. **Ticket primer status** — updates dependency chain in `docs/tickets/README.md` to mark completed ticket with checkmark.

**Does not:** Generate new documentation files. Write inline comments or docstrings. Update primer files beyond the status marker.

---

### 8. Agent/LLM Design (`/agent-design`) — Advisory

**When to invoke:** When working on code that touches LLM calls, prompts, tool definitions, or conversation state.

**Applies to:** Files in `app/services/llm/`, `app/services/tools/`, `app/channels/`, `config/prompts/`.

**Behavior:**
1. **Prompt review** — checks system prompts define role, boundaries, available tools. Flags open-ended or leaky prompts.
2. **Tool schema review** — validates `config/prompts/tool_definitions.yml` conventions: one tool per action, clear names, documented params. Flags overlaps.
3. **State handling check** — verifies session state is authoritative (backend DB). Flags LLM responses trusted to set state without application code validation.
4. **Structured output check** — verifies parsed LLM outputs have validation and fallback paths.
5. **Context window check** — reviews messages array. Flags unbounded history, missing system prompts, unnecessary data.

**Example output:**
```
RISK         app/channels/onboarding_chat_channel.rb:43 — assistant message saved from LLM content without validation; malformed response could persist bad data
IMPROVEMENT  app/services/llm/chat_service.rb:52 — streaming path sends unbounded history; consider truncation for long sessions
OK           config/prompts/tool_definitions.yml — 9 tools, no overlapping schemas
```

**Does not:** Rewrite prompts. Evaluate prompt quality/tone. Apply outside AI-related code.

---

## CLAUDE.md Integration

A `CLAUDE.md` at the project root, read by Claude Code every session:

```markdown
# Credal.ai — Claude Code Guidelines

## Project
AI-powered onboarding assistant. Rails 7.2 backend in `backend/`.
Ticket system in `docs/tickets/`. Read the primer before starting any ticket.

## Workflow — Mandatory Skill Invocations

### Starting a ticket
1. `/context-loading` — read primer, DEVLOG, dependency tickets, source files
2. `/source-control` — verify branch, clean state

### During implementation
3. `/tdd` — write tests first, red-green-refactor. No implementation without a failing test.
4. `/systems-design` — check before crossing module boundaries or adding services
5. `/scope-control` — check when editing files outside the ticket's listed scope
6. `/agent-design` — check when modifying LLM calls, prompts, tools, or conversation state

### Finishing a ticket
7. `/verify` — run tests, lint, staged file audit, deliverables check. Must pass before commit.
8. `/source-control` — commit conventions, staged file audit, PR creation
9. `/docs` — DEVLOG entry, README updates, ticket status

## Hard Gates (never skip)
- `/tdd` — no implementation code without a failing test
- `/source-control` — no commits to main, no dirty stages
- `/verify` — no commits with failing tests or missing deliverables

## Advisory (invoke, but can override with justification)
- `/systems-design`, `/scope-control`, `/context-loading`, `/docs`, `/agent-design`

## Stack Reference
- Ruby 3.2, Rails 7.2, PostgreSQL, Redis, Sidekiq, Devise
- React 18 (chat only), esbuild, Tailwind CSS
- OpenAI API (gpt-4o), LangSmith observability
- Tests: Minitest under `backend/test/`
```

---

## What This Design Does NOT Include

- **No hooks** — enforcement via CLAUDE.md convention, not pre-tool hooks
- **No skill chaining** — each skill is standalone, no automatic sequencing
- **No lifecycle orchestration** — no `/kickoff` or `/ship` meta-commands
- **No global skills** — all project-local, Credal-specific

These can be added later if the standalone approach proves insufficient.
