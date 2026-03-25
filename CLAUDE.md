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
