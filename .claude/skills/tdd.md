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
