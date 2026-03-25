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
