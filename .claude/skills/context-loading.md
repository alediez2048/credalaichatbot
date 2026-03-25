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
