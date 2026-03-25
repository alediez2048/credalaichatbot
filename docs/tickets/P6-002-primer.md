# P6-002 — Demo video recording (3-5 min)

**Priority:** P6
**Estimate:** 3 hours
**Phase:** 6 — Launch
**Status:** Not started

---

## Goal

Record a polished 3-5 minute demo video walking through the full onboarding assistant experience. The video serves as the primary showcase artifact for the portfolio, LinkedIn, and project README. It should demonstrate the end-to-end flow, highlight AI capabilities, and show the technical architecture briefly.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P6-002 |
|--------|----------------------|
| **P6-001** | App must be deployed to a public URL for the demo |
| **P1-002** | Core onboarding flow must work end-to-end |

---

## Deliverables Checklist

- [ ] Written script/outline covering all demo segments (see Script Outline below)
- [ ] Screen recording of full onboarding flow on production URL
- [ ] Voiceover or text captions explaining what is happening
- [ ] Brief architecture slide or overlay (15-20 seconds)
- [ ] Show LangSmith dashboard with traces (5-10 seconds)
- [ ] Show admin dashboard with stats (5-10 seconds)
- [ ] Opening title card: project name, your name, tech stack
- [ ] Closing card: GitHub link, live demo link
- [ ] Video exported as MP4, 1080p minimum
- [ ] Video uploaded to YouTube (unlisted or public) or Loom
- [ ] Thumbnail image created
- [ ] Video link added to README and DEVLOG

---

## Script Outline

| Segment | Duration | Content |
|---------|----------|---------|
| 1. Intro | 20s | Title card, "AI-powered employee onboarding assistant built with Rails + React + OpenAI" |
| 2. Landing page | 15s | Show landing page, explain the concept, click "Start Onboarding" |
| 3. Welcome step | 20s | Chat interface loads, assistant greets user, explain streaming |
| 4. Personal info | 45s | Provide name, email, phone — show conversational data collection |
| 5. Document upload | 30s | Show document step (stub or real), explain OCR pipeline if built |
| 6. Scheduling | 30s | Show scheduling step, explain slot recommendation if built |
| 7. Review & complete | 30s | Summary shown, confirmation, completion message |
| 8. Architecture | 20s | Quick slide: Rails 7.2, React, OpenAI gpt-4o, Action Cable, LangSmith |
| 9. Observability | 15s | Switch to LangSmith dashboard, show traces with token counts |
| 10. Admin dashboard | 15s | Show admin stats, completion funnel, cost summary |
| 11. Outro | 15s | GitHub link, live demo URL, "Thanks for watching" |

**Total: ~4 minutes**

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | Video is 3-5 minutes long | Check video duration |
| 2 | All onboarding steps shown | Watch video, verify each step appears |
| 3 | Audio or captions present | Watch with sound on / captions visible |
| 4 | Architecture overview included | Verify tech stack is explained |
| 5 | Video is 1080p or higher | Check video properties |
| 6 | Video is publicly accessible via link | Click link, verify playback |
| 7 | README updated with video link | Check README for embedded link |

---

## Recording Tips

- **Tool:** OBS Studio (free), Loom (easy sharing), or QuickTime (macOS)
- **Resolution:** 1920x1080 minimum, record at native resolution
- **Browser:** Use Chrome or Firefox, hide bookmarks bar, use clean profile
- **Font size:** Increase browser zoom to 110-125% for readability
- **Terminal:** If showing terminal, use large font (16pt+)
- **Prep:** Clear browser history, close notifications, use production URL
- **Audio:** Use a decent microphone, record in a quiet room; alternatively use text captions
- **Editing:** iMovie (macOS), DaVinci Resolve (free), or Loom's built-in editor

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All acceptance criteria verified
- [ ] `DEVLOG.md` updated with P6-002 entry and video link
- [ ] Video link added to project README

---

## Suggested Branch

```bash
git switch -c feature/P6-002-demo-video
```

---

## Out of Scope for P6-002

- Professional editing or motion graphics
- Multiple camera angles
- Separate deep-dive technical videos
