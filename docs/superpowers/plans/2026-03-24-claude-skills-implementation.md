# Claude Code Skills Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create 8 Claude Code skills in `.claude/skills/` and a `CLAUDE.md` at the project root that standardize the development workflow across both Cursor and Claude Code.

**Architecture:** Each skill is a standalone Markdown file with YAML frontmatter (`name`, `description`). Skills contain instructions Claude follows when invoked via slash command. `CLAUDE.md` wires skills into a ticket lifecycle. No hooks, no chaining.

**Tech Stack:** Markdown files only. No code dependencies.

**Spec:** `docs/superpowers/specs/2026-03-24-claude-skills-design.md`

**Commit convention note:** These are infrastructure/tooling commits (not ticket work), so they use `chore:` without a ticket reference. The `/source-control` skill's ticket-reference convention applies to ticket implementation work.

---

## File Map

| File | Responsibility |
|------|---------------|
| `.claude/skills/tdd.md` | Red-green-refactor enforcement (hard gate) |
| `.claude/skills/source-control.md` | Branch, commit, PR workflow (hard gate) |
| `.claude/skills/verify-before-done.md` | Pre-commit/pre-PR verification (hard gate) |
| `.claude/skills/systems-design.md` | Module boundary and data flow checks (advisory) |
| `.claude/skills/scope-control.md` | Ticket scope adherence (advisory) |
| `.claude/skills/context-loading.md` | Pre-implementation context gathering (advisory) |
| `.claude/skills/documentation.md` | DEVLOG, README, ticket status updates (advisory) |
| `.claude/skills/agent-design.md` | LLM/prompt/tool-call guardrails (advisory) |
| `CLAUDE.md` | Project root guidelines + workflow skill references |

All files are new. No existing files are modified.

---

### Task 1: Create `.claude/skills/` directory and TDD skill

**Files:**
- Create: `.claude/skills/tdd.md`

- [ ] **Step 1: Create the skills directory**

Run: `mkdir -p .claude/skills`

- [ ] **Step 2: Write `.claude/skills/tdd.md`**

```markdown
---
name: tdd
description: Red-green-refactor TDD enforcement. Invoke before implementing any feature or fix.
---

# Test-Driven Development — Hard Gate

You MUST follow this skill exactly. Do NOT write implementation code until a failing test exists.

## When to Invoke

Before implementing any feature or fix. This is a hard gate — you cannot skip it.

## Process

### 1. Assess

- Read the current ticket primer (`docs/tickets/P?-???-primer.md`) to understand deliverables and acceptance criteria.
- Identify what behavior needs to be tested.

### 2. Identify Test Files

- Check existing test structure under `backend/test/` (unit tests in `backend/test/unit/`, integration in `backend/test/integration/`).
- Follow existing naming conventions (e.g., `backend/test/unit/llm/chat_service_test.rb`).
- Name tests by behavior: `test_returns_error_when_api_key_missing`, not `test_chat_service`.

### 3. Red Phase — Write Tests First

- Write the test(s) that define the expected behavior.
- Run the specific test file:
  ```bash
  cd backend && bundle exec rails test test/unit/<path>_test.rb
  ```
- **Confirm the test fails for the RIGHT reason:**
  - **Right-reason failure:** Assertion failure because the behavior is not yet implemented (e.g., `NameError: uninitialized constant`, `NoMethodError`, `Expected X but got Y`).
  - **Wrong-reason failure:** Syntax errors in the test itself, missing `require` statements, unrelated test failures, configuration errors. Fix these before proceeding.
- **STOP if tests pass** — the test isn't testing new behavior. Rewrite it.

### 4. Green Phase — Minimum Implementation

- Write the minimum code to make the failing test(s) pass. Nothing more.
- Run the test file again. All tests in the file must be green.
- **STOP if any test fails.** Fix until green before moving on.

### 5. Refactor Phase — Only After Green

- Improve structure, remove duplication, clean up — but do NOT change behavior.
- Run tests again. Must still be green.
- If tests break during refactor, revert the refactor and try again.

### 6. Full Suite at End

- After all red-green-refactor cycles for the current task, run the full suite:
  ```bash
  cd backend && bundle exec rails test
  ```
- All tests must pass before you move to the next task or commit.

## What to Test (reference guidance)

When the ticket primer doesn't specify what to test, use these categories:

- **API and service boundaries:** Request/response shapes, status codes, error responses.
- **Business logic:** Validation rules, state transitions, field mapping.
- **Agent/LLM behavior:** Structured outputs, fallback paths when LLM returns invalid JSON. Use mocks/stubs, never live API calls.
- **OCR and data extraction:** Fixed sample documents, expected fields, confidence flags.
- **Error and fallback paths:** Timeouts, invalid input, "AI could not parse" flows.

## What NOT to Test

- Implementation details (internal function names, private state). Test observable behavior and contracts.
- Live LLM or external API calls in the main test suite. Use mocks, stubs, or recorded responses.

## Hard Gates — Non-Negotiable

- [ ] No implementation code exists without a failing test that motivated it
- [ ] No refactoring until all tests are green
- [ ] No declaring done with any test failing
- [ ] No committing with failing tests
```

- [ ] **Step 3: Verify the file was created**

Run: `cat .claude/skills/tdd.md | head -5`
Expected: Shows the frontmatter with `name: tdd`

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/tdd.md
git commit -m "chore: add TDD skill for Claude Code

Mirrors .cursor/rules/tdd.mdc with executable enforcement.
Hard gate: blocks implementation until failing tests exist."
```

---

### Task 2: Create source control skill

**Files:**
- Create: `.claude/skills/source-control.md`

- [ ] **Step 1: Write `.claude/skills/source-control.md`**

```markdown
---
name: source-control
description: Git branch, commit, and PR workflow enforcement. Invoke before starting a ticket and before committing.
---

# Source Control — Hard Gate

You MUST follow this skill exactly. Do NOT commit to main. Do NOT skip branch creation.

## When to Invoke

- Before starting work on a ticket (branch setup)
- Before committing (staged file audit, commit message)
- Before pushing/creating a PR

## At Ticket Start

### 1. Branch Check

- Run `git branch --show-current` to check current branch.
- **If on `main` or `master`:** Create a feature branch immediately.
  ```bash
  git switch -c feature/P?-???-short-name
  ```
  Example: `feature/P1-002-onboarding-orchestration`
- **If already on a feature branch:** Confirm it matches the ticket being worked.

### 2. Clean State Check

- Run `git status` to check for uncommitted changes.
- If there are uncommitted changes from prior work, warn the user: "You have uncommitted changes. Commit or stash them before starting a new ticket."

## At Commit Time

### 3. Staged File Audit

Run `git status` and check staged files. **BLOCK the commit if any of these are staged:**
- `.env`, `.env.*` (credentials)
- `.DS_Store` (macOS artifact)
- `credentials.json`, `master.key`, `*.key` (secrets)
- `node_modules/` (dependencies)
- `app/assets/builds/` (build artifacts)
- Files not related to the current ticket

### 4. Commit Message Format

Enforce Conventional Commits with ticket reference:
```
<type>(<ticket>): <description>
```

Valid types: `feat`, `test`, `fix`, `docs`, `refactor`, `chore`

Examples:
- `feat(P1-002): add onboarding state machine`
- `test(P1-002): add state transition tests`
- `fix(P1-002): handle nil session in controller`
- `docs(P1-002): update DEVLOG with P1-002 entry`

### 5. Small Logical Commits

If staged changes span multiple concerns (tests + implementation + docs), recommend splitting:
- First commit: tests (`test(P?-???): ...`)
- Second commit: implementation (`feat(P?-???): ...`)
- Third commit: docs (`docs(P?-???): ...`)

## At Push/PR Time

### 6. Branch Push

```bash
git push -u origin <branch-name>
```

### 7. PR Creation

Use `gh pr create` against `main` with structured body:
```bash
gh pr create --title "<type>(P?-???): <description>" --body "$(cat <<'EOF'
## Summary
- ...

## Test plan
- [ ] ...

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

## Hard Gates — Non-Negotiable

- [ ] Never commit directly to `main`
- [ ] Never stage `.env`, credentials, `.DS_Store`, or build artifacts
- [ ] Every commit uses Conventional Commit format with ticket reference
- [ ] Never force-push without explicit user approval
```

- [ ] **Step 2: Verify the file was created**

Run: `cat .claude/skills/source-control.md | head -5`
Expected: Shows the frontmatter with `name: source-control`

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/source-control.md
git commit -m "chore: add source control skill for Claude Code

Mirrors .cursor/rules/git-workflow.mdc with executable enforcement.
Hard gate: blocks commits to main, enforces Conventional Commits."
```

---

### Task 3: Create verify-before-done skill

**Files:**
- Create: `.claude/skills/verify-before-done.md`

- [ ] **Step 1: Write `.claude/skills/verify-before-done.md`**

```markdown
---
name: verify-before-done
description: Pre-commit and pre-PR verification gate. Invoke before committing, completing a ticket, or opening a PR.
---

# Verify Before Done — Hard Gate

You MUST run all checks below before committing or declaring work complete. Do NOT skip any check.

## When to Invoke

- Before every commit
- Before marking a ticket complete
- Before opening a PR

## Verification Checklist

### 1. Test Suite

Run the full test suite from `backend/`:
```bash
cd backend && bundle exec rails test
```

- **All tests must pass.** If any fail, STOP. Do not commit.
- If a test failure is pre-existing and unrelated to your changes, note it but do not introduce new failures.
- Do not delete or disable failing tests to make the suite pass.

### 2. Lint

Run linters (skip with a note if not yet configured):
```bash
cd backend && bundle exec rubocop 2>/dev/null || echo "RuboCop not configured — skipping"
cd backend && npx eslint app/javascript/ 2>/dev/null || echo "ESLint not configured — skipping"
```

- Report errors. Do not auto-fix.
- Do not add `# rubocop:disable` or `// eslint-disable` solely to silence warnings without a documented reason.

### 3. Staged File Audit

Run `git status` and verify:
- No `.env`, `.DS_Store`, credentials, or build artifacts are staged
- Only files related to the current ticket are staged
- No unintended file modifications (e.g., auto-formatter touching unrelated files)

### 4. Deliverables Checklist

- Read the current ticket primer's "Deliverables Checklist" section.
- Cross-reference each item against the git diff (`git diff --name-only main...HEAD` or against the branch base).
- Report each deliverable as done or missing.

### 5. Acceptance Criteria Spot-Check

- List the ticket's acceptance criteria.
- For automatable criteria: verify programmatically.
- For manual criteria (e.g., "works on 375px viewport"): prompt the user to confirm.

## Output Format

Report results in this format:
```
PASS    Tests (N passed, 0 failed)
PASS    Lint (no errors)
PASS    Staged files (no forbidden files)
FAIL    Deliverables: item 3 "Session persistence" — no matching code found
MANUAL  AC #4 "Works on 375px" — please confirm manually
```

## Hard Gates — Non-Negotiable

- [ ] No commit if any test fails
- [ ] No commit if forbidden files are staged
- [ ] No ticket marked complete if deliverables checklist has unchecked items
- [ ] Every FAIL must be resolved before proceeding
```

- [ ] **Step 2: Verify the file was created**

Run: `cat .claude/skills/verify-before-done.md | head -5`
Expected: Shows the frontmatter with `name: verify-before-done`

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/verify-before-done.md
git commit -m "chore: add verify-before-done skill for Claude Code

Mirrors .cursor/rules/verify-before-done.mdc with executable checks.
Hard gate: blocks commits on test failures and forbidden staged files."
```

---

### Task 4: Create systems design skill

**Files:**
- Create: `.claude/skills/systems-design.md`

- [ ] **Step 1: Write `.claude/skills/systems-design.md`**

```markdown
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
```

- [ ] **Step 2: Verify the file was created**

Run: `cat .claude/skills/systems-design.md | head -5`
Expected: Shows the frontmatter with `name: systems-design`

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/systems-design.md
git commit -m "chore: add systems design skill for Claude Code

Mirrors .cursor/rules/systems-design.mdc with boundary checks.
Advisory: flags violations but allows override with justification."
```

---

### Task 5: Create scope control skill

**Files:**
- Create: `.claude/skills/scope-control.md`

- [ ] **Step 1: Write `.claude/skills/scope-control.md`**

```markdown
---
name: scope-control
description: Ticket scope adherence checker. Invoke during implementation when editing files outside the ticket's listed scope.
---

# Scope Control — Advisory

This skill flags scope drift. You may override with justification. Advisory because Claude Code skills cannot prevent file edits, only flag them — achieving the same goal as .cursor/rules/scope-control.mdc through awareness.

## When to Invoke

During implementation, especially before editing files not listed in the ticket primer's scope.

## Checks

### 1. Load Ticket Scope

- Read the current ticket primer's "Deliverables Checklist" and "Files You Will Likely Modify / Create" sections.
- These define what's in bounds.

### 2. Diff Audit

- Run `git diff --name-only` (against the branch base or `main`) to see all modified files.
- Compare against the ticket's expected file list.
- Flag any file that doesn't appear in the primer's scope.

### 3. Change Classification

For each out-of-scope file, classify the change:

- **NECESSARY** — the ticket's work legitimately requires this edit (e.g., adding a route for a new controller, updating a shared config).
- **SCOPE CREEP** — unrelated cleanup, refactoring, or feature addition that is not part of the ticket.
- **ACCIDENTAL** — file was touched but shouldn't have been (e.g., auto-formatter, stale save).

### 4. Deliverables Progress

Cross-reference implemented work against the ticket's checklist:
```
PROGRESS  [x] Deliverable 1: ...  [ ] Deliverable 2: ...  [ ] Deliverable 3: ...
```

Report which items are done, which are pending, and which have no corresponding code yet.

## Output Format

```
SCOPE CREEP  path/to/file.rb — description (not in ticket deliverables)
NECESSARY    config/routes.rb — added route (required by deliverable #2)
OK           path/to/expected/file.rb — in scope
PROGRESS     [x] Done  [ ] Pending  [ ] Missing
```

## What to Do with Findings

- **SCOPE CREEP:** Revert the change and note it as a follow-up, or get explicit approval to include it.
- **ACCIDENTAL:** Revert the change.
- **NECESSARY:** Keep it — but document why in the commit message.

## Does NOT

- Revert changes automatically
- Prevent file edits
- Apply before implementation starts (use `/context-loading` for that)
```

- [ ] **Step 2: Verify the file was created**

Run: `cat .claude/skills/scope-control.md | head -5`
Expected: Shows the frontmatter with `name: scope-control`

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/scope-control.md
git commit -m "chore: add scope control skill for Claude Code

Mirrors .cursor/rules/scope-control.mdc with diff auditing.
Advisory: flags out-of-scope changes, allows override."
```

---

### Task 6: Create context loading skill

**Files:**
- Create: `.claude/skills/context-loading.md`

- [ ] **Step 1: Write `.claude/skills/context-loading.md`**

```markdown
---
name: context-loading
description: Pre-implementation context gathering. Invoke before starting work on any ticket.
---

# Context Loading — Advisory

Gather full context before writing any code. This skill prevents starting work with incomplete understanding.

## When to Invoke

Before starting implementation on any ticket. This should be the FIRST skill invoked when beginning a ticket.

## Process

### 1. Read the Ticket Primer

Load `docs/tickets/P?-???-primer.md` for the ticket being worked. Extract:
- Goal
- Deliverables checklist
- Acceptance criteria
- Technical notes
- Files to modify / create
- Files to read before coding

### 2. Read the DEVLOG

Load `docs/tickets/DEVLOG.md`. Look for:
- Prior decisions from dependency tickets that affect this work
- Follow-ups that are now relevant
- Patterns established in earlier tickets

### 3. Read Dependency Primers

Check the dependency tree in `docs/tickets/README.md` (the ASCII tree in the "Dependency chain" section using `├──` and `└──`). "Immediate parent" means the ticket(s) this ticket directly depends on (e.g., P1-002 depends on P1-001 which depends on P0-003).

Read the primers for immediate parent tickets to understand what's already in place.

### 4. Read Source Files

Open and read every file listed in:
- The primer's "Files You Will Likely Modify / Create"
- The primer's "Files You Should READ Before Coding"

Understand their current structure, patterns, and conventions before editing.

### 5. Produce Context Summary

Output a brief summary covering:
- **Goal:** What this ticket delivers
- **Prior decisions:** Key choices from dependency tickets
- **Existing patterns:** Conventions in the files you'll modify (test naming, service structure, etc.)
- **Open follow-ups:** Relevant items from DEVLOG
- **Blockers:** Any prerequisites not yet met

## Warnings

- If a prerequisite ticket is not marked done in DEVLOG, warn: "Prerequisite P?-??? may not be complete."
- If a file listed in the primer doesn't exist, classify it:
  - **Expected to create** — the primer says you'll create it
  - **Possibly missing** — the primer says to read it but it doesn't exist

## Does NOT

- Create branches or write code — purely informational
- Duplicate what the primer already says — synthesizes across sources
- Replace reading the primer — you should still read it directly
```

- [ ] **Step 2: Verify the file was created**

Run: `cat .claude/skills/context-loading.md | head -5`
Expected: Shows the frontmatter with `name: context-loading`

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/context-loading.md
git commit -m "chore: add context loading skill for Claude Code

Mirrors .cursor/rules/context-loading.mdc with ticket-aware context gathering.
Advisory: reads primers, DEVLOG, dependencies before implementation."
```

---

### Task 7: Create documentation skill

**Files:**
- Create: `.claude/skills/documentation.md`

- [ ] **Step 1: Write `.claude/skills/documentation.md`**

```markdown
---
name: documentation
description: DEVLOG, README, and ticket status updates. Invoke after completing a ticket's implementation.
---

# Documentation Updates — Advisory

Keep project documentation current after each ticket. This skill does not generate new docs from scratch — it updates existing documentation to reflect what shipped.

## When to Invoke

After completing a ticket's implementation, before or alongside the final commit.

## Process

### 1. DEVLOG Entry

Generate a draft entry for `docs/tickets/DEVLOG.md` following the template at the top of that file:

```markdown
### P?-??? — Title
**Date:** YYYY-MM-DD
**Branch:** feature/P?-???-short-name

**What shipped:**
- (derived from git diff and deliverables checklist)

**Decisions:**
- (architectural or technical choices made during implementation)

**Follow-ups / debt:**
- (anything out of scope but worth tracking)
```

- Derive "What shipped" from `git diff --stat main...HEAD` and the ticket's deliverables checklist.
- Include "Decisions" only for choices that affect future tickets.
- Include "Follow-ups" for issues noticed but not fixed (scope control).
- **Present the draft to the user for review before writing it.**

### 2. README Check

Scan `backend/README.md` for sections that may need updating based on what changed:

- **New env vars** — check if any new `ENV[]` references were added. If so, flag the "Setup" or equivalent section.
- **New setup steps** — new dependencies, new migrations, new build commands.
- **New tables** — check migrations. If a new table was added, flag the "Core tables" section.
- **Changed commands** — if Procfile, bin/dev, or run commands changed.

If nothing needs updating, say so. Do not force unnecessary README changes.

### 3. Ticket Status Update

Update the dependency chain in `docs/tickets/README.md`:
- Find the line for the completed ticket in the ASCII dependency tree.
- Add a ✅ checkmark after the ticket description.
- Example: `├── P0-003 (LLM service + tools) ✅`

## Does NOT

- Generate new documentation files or READMEs
- Write inline code comments or docstrings
- Update primer files beyond the status marker
- Auto-commit — presents changes for review first
```

- [ ] **Step 2: Verify the file was created**

Run: `cat .claude/skills/documentation.md | head -5`
Expected: Shows the frontmatter with `name: documentation`

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/documentation.md
git commit -m "chore: add documentation skill for Claude Code

New skill (no cursor rule equivalent) for DEVLOG, README, and ticket status.
Advisory: drafts updates for review before writing."
```

---

### Task 8: Create agent/LLM design skill

**Files:**
- Create: `.claude/skills/agent-design.md`

- [ ] **Step 1: Write `.claude/skills/agent-design.md`**

```markdown
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
```

- [ ] **Step 2: Verify the file was created**

Run: `cat .claude/skills/agent-design.md | head -5`
Expected: Shows the frontmatter with `name: agent-design`

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/agent-design.md
git commit -m "chore: add agent design skill for Claude Code

Mirrors .cursor/rules/agent-design.mdc with AI-specific guardrails.
Advisory: reviews prompts, tool schemas, state handling, context window."
```

---

### Task 9: Create CLAUDE.md

**Files:**
- Create: `CLAUDE.md` (project root)

- [ ] **Step 1: Write `CLAUDE.md`**

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
- Run tests: `cd backend && bundle exec rails test`
- Run server: `cd backend && bin/dev`
```

- [ ] **Step 2: Verify the file was created**

Run: `cat CLAUDE.md | head -3`
Expected: `# Credal.ai — Claude Code Guidelines`

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "chore: add CLAUDE.md for Claude Code workflow integration

Wires 8 skills into ticket lifecycle: context-loading, source-control,
tdd, systems-design, scope-control, agent-design, verify, docs."
```

---

### Task 10: Final verification

**Files:**
- Read: all files created in tasks 1-9

- [ ] **Step 1: Verify all 8 skills exist**

Run: `ls -la .claude/skills/`
Expected: 8 `.md` files:
```
agent-design.md
context-loading.md
documentation.md
scope-control.md
source-control.md
systems-design.md
tdd.md
verify-before-done.md
```

- [ ] **Step 2: Verify CLAUDE.md exists at project root**

Run: `cat CLAUDE.md | head -3`
Expected: `# Credal.ai — Claude Code Guidelines`

- [ ] **Step 3: Verify all skill frontmatter is valid**

Run: `head -4 .claude/skills/*.md`
Expected: Each file starts with `---`, has `name:` and `description:`, ends with `---`

- [ ] **Step 4: Verify git log shows all commits**

Run: `git log --oneline -10`
Expected: 9 commits (tasks 1-9), all using Conventional Commit format

- [ ] **Step 5: Run any existing tests to confirm nothing is broken**

Run: `cd backend && bundle exec rails test`
Expected: All existing tests pass (these are markdown-only changes, no code impact)
