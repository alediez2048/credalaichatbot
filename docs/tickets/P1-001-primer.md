# P1-001 — Chat interface with streaming LLM responses

**Priority:** P0  
**Estimate:** 4 hours  
**Phase:** 1 — AI Chatbot Core (MVP GATE)  
**PRD reference:** `PRD - AI-Powered Onboarding Assistant.md` §7  

---

## Goal

Deliver a React chat UI mounted in the `/onboarding` view (set up by P1-000) where the user sees their message immediately, the assistant reply streams token-by-token over Action Cable with a typing indicator, the thread auto-scrolls, layout works at 375px width, and every message is persisted via the `Message` model.

---

## Prerequisites (BLOCKERS)

**P1-001 cannot start until Phase 0 and P1-000 are in place.**

| Ticket | Why it blocks P1-001 |
|--------|----------------------|
| **P0-001** | Rails app, PostgreSQL, Action Cable, `Message` model + migrations |
| **P0-002** | `LLM::ChatService` (or equivalent) must expose a streaming path the channel can consume |
| **P0-003** | Optional for first slice; system prompt can be stubbed until wired |
| **P0-005** | esbuild + React + Tailwind toolchain — React cannot compile without esbuild |
| **P1-000** | Landing page + `/onboarding` route with chat container mount point |

**If no app exists in the repo:** complete **P0-001** first (scaffold + `Message` + Action Cable handshake), then **P0-005** (frontend toolchain), then **P0-002** (LLM service), then **P1-000** (landing + routing), then implement P1-001.

---

## Deliverables Checklist

- [ ] React chat component mounted in a Rails view (e.g. `app/views/onboarding/chat.html.erb` + JS entry)
- [ ] User message appears in the thread immediately on send (optimistic or post-save)
- [ ] Assistant reply streams token-by-token via Action Cable
- [ ] Typing indicator while assistant is generating
- [ ] Auto-scroll to bottom on new content / stream chunks
- [ ] Layout usable at 375px width (mobile-first or responsive breakpoints)
- [ ] Messages persisted: create `Message` records for user + assistant turns

---

## Acceptance Criteria (from PRD)

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | User types a message and sees it appear immediately | Manual: send message → bubble appears without waiting for full AI response |
| 2 | AI response streams token-by-token with typing indicator | Manual: observe incremental text + indicator clears when done |
| 3 | Chat scrolls to latest message automatically | Manual: long thread → new message/scroll stays at bottom |
| 4 | Works on mobile viewport (375px) | DevTools responsive or device |
| 5 | Messages persist in the database | Reload page → history loads from `Message` |

---

## Technical Notes (first principles)

- **Single source of truth:** Server persists messages; client may show optimistic user message then reconcile with server ID if needed.
- **Streaming contract:** Action Cable channel receives chunks (e.g. `{ type: 'token', content: '...' }` + `{ type: 'done' }`). Do not couple React to OpenAI SDK directly—stream from `LLM::ChatService` through the channel.
- **Session binding:** Associate messages with `OnboardingSession` (or session UUID) from P0-001 so P1-003 resumption can load history later.
- **Error path:** If stream fails, show a single assistant bubble with a graceful message (aligned with P1-004 later; for P1-001, minimal try/rescue + cable broadcast error event).

---

## Files You Will Likely Modify / Create

*Exact paths depend on P0-001 layout; adjust after scaffold exists.*

| Area | Likely paths |
|------|----------------|
| Channel | `app/channels/chat_channel.rb` (or `onboarding_chat_channel.rb`) |
| Connection | `app/channels/application_cable/connection.rb` (identify session/user) |
| Consumer | `app/javascript/channels/chat_channel.js` or React hook subscribing to cable |
| React UI | `app/javascript/components/Chat.jsx` (or `.tsx`) + CSS/Tailwind |
| View mount | `app/views/.../chat.html.erb` + pack/import |
| Controller | Action that renders chat page + creates session if needed |
| Model | `app/models/message.rb` (validations, `onboarding_session_id`, role, content) |
| Job/service | Service object called from channel to stream LLM (delegates to `LLM::ChatService`) |

---

## Files You Should NOT Modify (unless ticket expands)

- OCR, scheduling, or document upload code (Phase 2+)
- Devise views except if required to reach chat route after login/anonymous flow (P1-005 handles merge separately)

---

## Files You Should READ Before Coding

1. PRD §6 Phase 0 and §7 Phase 1 (streaming + Message persistence)
2. `presearch-appendix.md` — Action Cable / real-time decisions
3. Existing `Message` model + migration after P0-001
4. `LLM::ChatService` (or equivalent) streaming API after P0-002
5. `.cursor/rules/agent-design.mdc` — state and turn handling

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All acceptance criteria verified manually (and automated tests where feasible, e.g. channel subscribe, Message creation)
- [ ] `DEVLOG.md` updated with P1-001 entry
- [ ] Feature branch pushed; PR ready for review
- [ ] No commit to `main` without review (per `.cursor/rules/git-workflow.mdc`)

---

## Suggested Branch

```bash
git switch -c feature/P1-001-chat-streaming
```

---

## Out of Scope for P1-001

- Full onboarding orchestration (P1-002)
- Session resumption / summarization (P1-003)
- Rate limiting (P1-006)
- Anonymous merge (P1-005)

Implement the **chat shell + streaming + persistence** only; orchestration can call the same channel later.
