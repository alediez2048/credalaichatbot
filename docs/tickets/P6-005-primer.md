# P6-005 — Social post & launch

**Priority:** P6
**Estimate:** 1 hour
**Phase:** 6 — Launch
**Status:** Not started

---

## Goal

Craft and publish a LinkedIn and/or Twitter/X post announcing the project. The post links to the live demo, GitHub repo, and demo video. This is the final ticket in the project — the public launch.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P6-005 |
|--------|----------------------|
| **P6-001** | Production URL must be live |
| **P6-002** | Demo video must be recorded and uploaded |
| **P6-003** | GitHub repo must be documented and public |
| **P6-004** | Cost analysis complete (can reference findings in post) |

---

## Deliverables Checklist

- [ ] LinkedIn post draft written and reviewed
- [ ] Twitter/X post draft written and reviewed (optional, LinkedIn is primary)
- [ ] Post includes: project description (2-3 sentences), key tech highlights, live demo link, GitHub link, demo video link/embed
- [ ] Thumbnail or preview image created (screenshot of chat interface or architecture diagram)
- [ ] Post published on LinkedIn
- [ ] Post published on Twitter/X (optional)
- [ ] Links verified working after publish
- [ ] `docs/launch/social-posts.md` — saved copy of published posts with links

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | LinkedIn post is published and publicly visible | Visit post URL |
| 2 | Post contains live demo link | Click link, verify app loads |
| 3 | Post contains GitHub link | Click link, verify repo loads |
| 4 | Post contains demo video link or embed | Click link, verify video plays |
| 5 | Post describes what the project does and the tech stack | Read post |
| 6 | Saved copy exists in repo | Check `docs/launch/social-posts.md` |

---

## Post Templates

### LinkedIn post

```
I built an AI-powered employee onboarding assistant from scratch.

The chatbot guides new hires through the entire onboarding process — collecting personal information, handling document uploads, scheduling appointments — all through natural conversation.

Tech stack:
- Ruby on Rails 7.2 + React 18
- OpenAI gpt-4o with function calling
- Real-time streaming via Action Cable
- LangSmith for observability & tracing
- Automated eval suite (50+ test cases)
- Cost tracking & projection model

Key highlights:
- Full conversational flow with 6 onboarding steps
- Server-side tool execution for structured data collection
- End-to-end tracing of every LLM call
- Admin dashboard with completion funnel and cost metrics
- CI pipeline that catches prompt regressions

[Live demo] [GitHub] [Demo video]

Built as a portfolio project demonstrating production-grade AI engineering — from prompt design and tool calling to cost optimization and observability.

#AI #LLM #OpenAI #RubyOnRails #React #MachineLearning #SoftwareEngineering #Portfolio
```

### Twitter/X post

```
Built an AI onboarding assistant with Rails + React + OpenAI gpt-4o

- Conversational flow through 6 onboarding steps
- Function calling for structured data collection
- Real-time streaming via Action Cable
- LangSmith tracing + eval suite
- Admin dashboard + cost tracking

[Demo] [GitHub] [Video]
```

---

## Image/Thumbnail Guidance

- Screenshot of the chat interface mid-conversation (showing a few exchanges)
- Alternatively: side-by-side of chat + LangSmith trace
- Dimensions: 1200x627px (LinkedIn recommended) or 1200x675px (Twitter)
- Add project name as text overlay if desired
- Tools: Figma, Canva, or a simple screenshot with border

---

## New files

| File | Purpose |
|------|---------|
| `docs/launch/social-posts.md` | Saved copy of published posts with URLs |

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All acceptance criteria verified
- [ ] `DEVLOG.md` updated with P6-005 entry (include post URLs)
- [ ] Project complete

---

## Suggested Branch

```bash
git switch -c feature/P6-005-launch
```

---

## Out of Scope for P6-005

- Paid promotion or advertising
- Blog post or detailed write-up (could be a follow-up)
- Product Hunt launch
- Community engagement / responding to comments (do this naturally)
