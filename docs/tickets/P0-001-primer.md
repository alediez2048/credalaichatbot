# P0-001 — Rails project scaffolding & database setup

**Status:** Kickstarted — app lives in `backend/`.

## Acceptance criteria

| Criterion | How |
|-----------|-----|
| Rails boots with `bin/dev` / server | `cd backend && bundle install && bin/rails db:create db:migrate && bin/rails server` |
| Migrations run | Seven migrations create users, onboarding_sessions, messages, documents, extracted_fields, bookings, audit_logs |
| Devise signup/login/logout | Root links to Devise; `devise_for :users` |
| Sidekiq processes jobs | `bundle exec sidekiq` with Redis; `config.active_job.queue_adapter = :sidekiq` |
| Action Cable connects | Redis adapter in `config/cable.yml`; `PingChannel` for smoke test |

## Layout

- **App root:** `backend/` (repo root still holds PRD, Docs, `.cursor/rules`).
- **Ruby:** 3.1+ required; `.ruby-version` pins 3.2.0.

## After clone

```bash
cd backend
bundle install
bin/rails db:create db:migrate
bin/rails server
```

Redis must run for Cable + Sidekiq in dev.

## Next

- **P0-002** — LLM::ChatService, Tools::Router, tool YAML
