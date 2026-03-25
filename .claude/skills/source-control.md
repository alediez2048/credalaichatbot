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
