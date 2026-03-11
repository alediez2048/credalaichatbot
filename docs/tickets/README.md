# Tickets

Ticket primers live here. Before coding any ticket:

1. Read **`P{phase}-{id}-primer.md`** for that ticket.
2. Read **DEVLOG.md** for prior decisions and blockers.
3. Follow `.cursor/rules/context-loading.mdc` and `scope-control.mdc`.

## Form factor

**Landing page** (`/`) → **Full-screen chatbot** (`/onboarding`). The chat IS the onboarding.

## Phase order

| Phase | Focus |
|-------|--------|
| **P0** | Rails scaffold, LLM service + tools, prompts, observability |
| **P1** | Landing page, chat UI, streaming, orchestration, persistence, errors, anonymous merge, rate limits |
| **P2+** | OCR, scheduling, emotional support, evals, deploy |

## Dependency chain

```
P0-001 (scaffold) ✅ DONE
├── P0-002 (LLM service + tools)
│   ├── P0-003 (prompts)
│   └── P0-004 (observability)
├── P1-000 (landing page + routing) ← NEW
│   └── P1-001 (chat UI + streaming) — needs P0-002 + P1-000
│       └── P1-002 (onboarding orchestration)
│           └── P1-003 (session persistence)
└── P1-005 (anonymous merge)
```

**P0-001** is scaffolded under **`backend/`** — run `bundle install` and `db:migrate` there.
