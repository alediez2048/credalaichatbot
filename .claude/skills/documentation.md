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
