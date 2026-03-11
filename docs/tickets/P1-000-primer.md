# P1-000 — Landing page & routing

**Priority:** P0
**Estimate:** 2 hours
**Phase:** 1 — AI Chatbot Core (MVP GATE)
**PRD reference:** `PRD - AI-Powered Onboarding Assistant.md` §6 (Form Factor), §8 (Phase 1)

---

## Goal

Build the landing page at `/` and the `/onboarding` route so the app has a clear entry point and user journey. The landing page is what evaluators, demo viewers, and users see first — it needs to look polished and professional. The `/onboarding` route renders the chat container that P1-001 will populate.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P1-000 |
|--------|----------------------|
| **P0-001** | Rails app, Devise auth, routes, base layout |

P0-003/P0-004 are NOT blockers — the landing page and routing are independent of the AI service layer.

---

## Deliverables Checklist

- [ ] Landing page at `/` with hero section, product description, and CTA
- [ ] `/onboarding` route renders a chat container page
- [ ] Sign in / Sign up links on landing page
- [ ] Authenticated users clicking CTA go to `/onboarding`
- [ ] Anonymous users clicking CTA go to `/onboarding` (auth deferred to document upload per P1-005)
- [ ] Mobile-responsive layout (375px width)
- [ ] Minimal but clean styling (Tailwind CSS or scoped custom CSS)

---

## Acceptance Criteria (from PRD)

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | `/` shows a polished landing page | Manual: visit root URL, see hero + CTA + nav |
| 2 | "Start Onboarding" links to `/onboarding` | Manual: click CTA → arrives at chat page |
| 3 | Sign in / Sign up visible on landing | Manual: links work, Devise forms render |
| 4 | `/onboarding` renders chat container | Manual: page loads with empty chat shell or placeholder |
| 5 | Works on mobile (375px) | DevTools responsive mode |
| 6 | Authenticated user sees their state | Manual: signed-in user sees email/sign out in nav |

---

## Technical Notes

- **Landing page is server-rendered** — Hotwire/ERB, no React. Keep it simple.
- **Chat page is a separate view** — `app/views/onboarding/chat.html.erb` with a `<div id="chat-root">` mount point for the React component (P1-001).
- **Routing:** Add `OnboardingController#chat` and route `get '/onboarding', to: 'onboarding#chat'`. Keep `root 'home#index'`.
- **Styling:** If Tailwind is not already set up, either add it or use a small scoped stylesheet. The landing page needs to look presentable — not beautiful, but professional.
- **No auth gate on `/onboarding`** — anonymous users can access it. Auth is enforced at document upload time (P1-005).

---

## Files You Will Likely Create / Modify

| Area | Likely paths |
|------|----------------|
| Controller | `app/controllers/onboarding_controller.rb` |
| Views | `app/views/home/index.html.erb` (rewrite), `app/views/onboarding/chat.html.erb` (new) |
| Layout | `app/views/layouts/application.html.erb` (nav/styling) |
| Routes | `config/routes.rb` (add `/onboarding`) |
| Styles | `app/assets/stylesheets/` or Tailwind config |

---

## Landing Page Content (suggested)

```
[Nav: Logo — Sign In | Sign Up]

AI-Powered Onboarding Assistant
Complete your employee onboarding in minutes — not hours.

Our AI assistant guides you through every step: data collection,
document verification, and appointment scheduling — with a
supportive, human touch.

[Start Onboarding →]

Features:
• AI-guided conversational flow
• Instant document scanning & data extraction
• Smart appointment scheduling
• Progress tracking & emotional support

Built for Credal.ai · Powered by GPT-4o
```

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All acceptance criteria verified manually
- [ ] `DEVLOG.md` updated with P1-000 entry
- [ ] Feature branch pushed; PR ready for review

---

## Suggested Branch

```bash
git switch -c feature/P1-000-landing-page
```

---

## Out of Scope for P1-000

- React chat component (P1-001)
- LLM integration (P0-003)
- Onboarding orchestration (P1-002)
- Auth gating on chat (P1-005)
