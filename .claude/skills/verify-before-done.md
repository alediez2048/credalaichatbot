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
