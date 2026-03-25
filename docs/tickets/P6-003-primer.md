# P6-003 — GitHub repository documentation

**Priority:** P6
**Estimate:** 3 hours
**Phase:** 6 — Launch
**Status:** Not started

---

## Goal

Write comprehensive repository documentation so that anyone (recruiter, engineer, open-source contributor) can understand the project, set it up locally, and navigate the codebase. This includes a polished root README, architecture documentation, and a setup guide.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P6-003 |
|--------|----------------------|
| **P6-001** | Production URL needed for live demo link |
| **P6-002** | Demo video link to embed in README |

---

## Deliverables Checklist

- [ ] Root `README.md` — project overview, demo GIF/video, tech stack, features list, quick start, architecture summary, live demo link
- [ ] `docs/architecture.md` — system architecture diagram (ASCII or Mermaid), component descriptions, data flow
- [ ] `docs/setup.md` — step-by-step local development setup (Ruby, Node, PostgreSQL, Redis, env vars, seed data)
- [ ] `docs/api.md` — Action Cable channel protocol, message formats, tool call interface
- [ ] `backend/README.md` updated with backend-specific setup, test commands, directory structure
- [ ] `.env.example` reviewed and documented (every variable explained with comments)
- [ ] `LICENSE` file added (MIT recommended)
- [ ] Badges in root README: Ruby version, Rails version, tests passing, license
- [ ] Screenshots of: landing page, chat interface, admin dashboard (placed in `docs/images/`)
- [ ] Contributing section in README (or `CONTRIBUTING.md` if detailed)

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | New developer can set up locally following only the docs | Fresh clone, follow setup.md, app runs |
| 2 | README has project description, demo link, and tech stack | Read README |
| 3 | Architecture doc explains all major components | Read docs/architecture.md |
| 4 | All env vars documented with purpose | Check .env.example comments |
| 5 | Screenshots present and rendering in markdown | View README on GitHub |
| 6 | License file exists | Check root directory |

---

## Architecture Doc Structure

```markdown
# Architecture

## System Overview
[Mermaid diagram or ASCII art showing: Browser -> Rails -> Action Cable -> LLM Service -> OpenAI]

## Components
- **Frontend:** React chat component, Tailwind CSS, esbuild
- **Backend:** Rails 7.2 API + Action Cable
- **AI Layer:** LLM::ChatService, Tools::Router, Onboarding::Orchestrator
- **Observability:** LangSmith tracing via Observability::Tracer
- **Storage:** PostgreSQL (sessions, messages, usage), Redis (Action Cable, Sidekiq)

## Data Flow
1. User sends message via WebSocket (Action Cable)
2. OnboardingChatChannel receives, persists, calls Orchestrator
3. Orchestrator builds context, calls ChatService
4. ChatService calls OpenAI with tools, traces via LangSmith
5. Tool calls routed through Tools::Router
6. Response streamed back to client via Action Cable

## Directory Structure
backend/
  app/
    channels/        # Action Cable channels
    controllers/     # Rails controllers
    javascript/      # React components
    models/          # ActiveRecord models
    services/        # Service objects (llm/, tools/, onboarding/, eval/, cost/, admin/)
    views/           # ERB templates
  config/
    prompts/         # YAML prompt and tool definitions
  test/
    eval/            # Eval test cases
docs/
  tickets/           # Primer files and DEVLOG
  ops/               # Operational guides
```

---

## README Structure

```markdown
# Credal.ai Onboarding Assistant

> AI-powered employee onboarding chatbot built with Rails 7.2, React, and OpenAI gpt-4o

[Demo Video] | [Live Demo] | [Architecture]

## Features
- Conversational onboarding flow (6 steps)
- Real-time streaming via Action Cable
- OpenAI function calling for structured data collection
- LangSmith observability and tracing
- Automated eval suite (50+ test cases)
- Admin analytics dashboard
- Cost tracking and projection

## Tech Stack
- **Backend:** Ruby on Rails 7.2, PostgreSQL, Redis, Sidekiq
- **Frontend:** React 18, Tailwind CSS, esbuild
- **AI:** OpenAI gpt-4o, function calling, streaming
- **Observability:** LangSmith
- **Deployment:** [Render/Fly.io]

## Quick Start
[Link to docs/setup.md]

## Architecture
[Link to docs/architecture.md]

## Screenshots
[Landing page, Chat, Admin dashboard]

## License
MIT
```

---

## New files

| File | Purpose |
|------|---------|
| `README.md` (root, rewrite) | Polished project README |
| `docs/architecture.md` | System architecture documentation |
| `docs/setup.md` | Local development setup guide |
| `docs/api.md` | Action Cable and API protocol docs |
| `LICENSE` | MIT license |
| `docs/images/*.png` | Screenshots |

### Modified files

| File | Changes |
|------|---------|
| `backend/README.md` | Update with backend-specific details |
| `.env.example` | Add comments explaining each variable |

---

## Files You Should READ Before Coding

1. `backend/README.md` — current backend docs
2. `.env.example` — current env var list
3. `docs/tickets/README.md` — project structure reference
4. `config/routes.rb` — all routes for API documentation
5. `app/channels/onboarding_chat_channel.rb` — WebSocket protocol

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All acceptance criteria verified
- [ ] `DEVLOG.md` updated with P6-003 entry
- [ ] Feature branch pushed; PR ready for review

---

## Suggested Branch

```bash
git switch -c feature/P6-003-repo-docs
```

---

## Out of Scope for P6-003

- API versioning or Swagger/OpenAPI spec
- Detailed contribution workflow (code review, branch strategy)
- Changelog (DEVLOG serves this purpose)
