# Tickets

**Canonical location:** `docs/tickets/` — all ticket docs live here.

## Index (one primer per ticket)

| File | Use it for |
|------|-------------|
| **P0-001-primer.md** | Rails scaffold + DB: acceptance criteria and step-by-step setup (Ruby, Postgres, Redis, `.env`, `bundle`, `db:migrate`). |
| **P0-002-primer.md** | Frontend toolchain: esbuild + Tailwind CSS + React setup, styling migration. |
| **P0-003-primer.md** | AI service layer: Tools::Router, SchemaValidator, LLM::ChatService, ContextBuilder, 9 tools in YAML, OpenAI function calling. |
| **P0-004-primer.md** | Prompt management: system prompt in YAML, PromptLoader, version-tracking; no hardcoded prompts. |
| **P0-005-primer.md** | Observability & tracing: LangSmith or Langfuse, instrument ChatService (tokens, latency, session_id). |
| **P1-000-primer.md** | Landing page + `/onboarding` route: deliverables, acceptance criteria, content spec. |
| **P1-001-primer.md** | Chat UI + streaming: scope, prerequisites (P0-002 + P0-003 + P1-000), file hints. |
| **DEVLOG.md** | What shipped per ticket, decisions, follow-ups. Update when you finish a ticket. |

Before coding any ticket:

1. Read the **primer** for that ticket (`P?-???-primer.md`).
2. Read **DEVLOG.md** for prior decisions and blockers.
3. Follow `.cursor/rules/context-loading.mdc` and `scope-control.mdc`.

## Form factor

**Landing page** (`/`) → **Full-screen chatbot** (`/onboarding`). The chat IS the onboarding.

## Frontend stack

**Tailwind CSS** for all styling. **Hotwire/ERB** for server-rendered pages (landing, admin, Devise). **React** for the chat component only. **esbuild** for JS bundling (JSX support).

## Phase order

| Phase | Focus |
|-------|--------|
| **P0** | Rails scaffold, frontend toolchain (esbuild + Tailwind + React), LLM service + tools, prompts, observability |
| **P1** | Landing page, chat UI, streaming, orchestration, persistence, errors, anonymous merge, rate limits |
| **P2+** | OCR, scheduling, emotional support, evals, deploy |

## Dependency chain

```
P0-001 (scaffold) ✅ DONE
├── P0-002 (esbuild + Tailwind + React) ✅ DONE
│   └── P1-000 (landing page + routing) ✅ DONE
├── P0-003 (LLM service + tools) ← NEXT
│   ├── P0-004 (prompts)
│   ├── P0-005 (observability)
│   └── P1-001 (chat UI + streaming)
│       └── P1-002 (onboarding orchestration)
└── P1-005 (anonymous merge)
```

**P0-001** is scaffolded under **`backend/`** — run `bundle install` and `db:migrate` there.
