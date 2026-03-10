# Tickets

Ticket primers live here. Before coding any ticket:

1. Read **`P{phase}-{id}-primer.md`** for that ticket.
2. Read **DEVLOG.md** for prior decisions and blockers.
3. Follow `.cursor/rules/context-loading.mdc` and `scope-control.mdc`.

## Phase order

| Phase | Focus |
|-------|--------|
| **P0** | Rails scaffold, LLM service + tools, prompts, observability |
| **P1** | Chat UI, streaming, orchestration, persistence, errors, anonymous merge, rate limits |
| **P2+** | OCR, scheduling, emotional support, evals, deploy |

**P0-001** is scaffolded under **`backend/`** — run `bundle install` and `db:migrate` there.

**P1-001** requires **P0-001** and **P0-002** first.
