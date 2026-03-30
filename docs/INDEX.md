# Docs Index — Credal.ai Onboarding Assistant

## Research & Discovery
Background research, interviews, and requirements gathered before building.

| File | Description |
|------|-------------|
| [research/credal-research.md](research/credal-research.md) | Credal.ai company and product research |
| [research/credal-requirements.md](research/credal-requirements.md) | Functional and technical requirements |
| [research/interviews.md](research/interviews.md) | Stakeholder interview notes |
| [research/presearch-appendix.md](research/presearch-appendix.md) | Pre-research appendix and references |

## Design & Specifications
Product requirements, style guides, and feature design specs.

| File | Description |
|------|-------------|
| [design/PRD.md](design/PRD.md) | Product Requirements Document — full spec |
| [design/credal-style-guidelines.md](design/credal-style-guidelines.md) | Credal brand: colors, typography, UI patterns |
| [design/nclusion-design-style-guide.md](design/nclusion-design-style-guide.md) | Nclusion design reference (cross-project) |
| [design/P7-openclaw-architecture-impact.md](design/P7-openclaw-architecture-impact.md) | Architecture impact: OpenClaw as omnichannel agent gateway |
| [superpowers/specs/](superpowers/specs/) | Feature design specs (brainstormed + reviewed) |
| [superpowers/plans/](superpowers/plans/) | Implementation plans |

## Tickets & Development Log
Phased ticket system and development history.

| File | Description |
|------|-------------|
| [tickets/README.md](tickets/README.md) | Ticket index with dependency tree |
| [tickets/DEVLOG.md](tickets/DEVLOG.md) | What shipped per ticket, decisions, follow-ups |
| [tickets/PREFLIGHT-CHECKLIST.md](tickets/PREFLIGHT-CHECKLIST.md) | Pre-launch verification checklist |
| `tickets/P?-???-primer.md` | 42 ticket primers (P0-001 through P7-007) |

### Ticket Phases

| Phase | Category | Tickets | Status |
|-------|----------|---------|--------|
| **P0** | Foundation & Setup | P0-001 — P0-005 | Done |
| **P1** | AI Chatbot Core (MVP) | P1-000 — P1-006 | Done |
| **P2** | Document Upload & OCR | P2-001 — P2-005 | Done |
| **P3** | Scheduling & Booking | P3-001 — P3-004 | Done |
| **P4** | Emotional Support | P4-001 — P4-004 | Done |
| **P5** | Evals & Ops | P5-001 — P5-005 | Done |
| **P6** | Launch | P6-001 — P6-005 | Done |
| **P7** | Omnichannel Continuity (OpenClaw gateway + admin + Render ops) | P7-001 — P7-007 | In progress (P7-001–003 done) |

## Guides
Step-by-step integration and configuration guides.

| File | Description |
|------|-------------|
| [guides/openclaw-integration.md](guides/openclaw-integration.md) | OpenClaw gateway setup: install, channels, hooks → Rails, testing, troubleshooting |

## Ops & Infrastructure
Production deployment, CI/CD, and observability.

| File | Description |
|------|-------------|
| [ops/production.md](ops/production.md) | Production deployment guide |
| [ops/ci-eval.md](ops/ci-eval.md) | CI eval pipeline configuration |
| [ops/langsmith-dashboard.md](ops/langsmith-dashboard.md) | LangSmith tracing dashboard setup |
