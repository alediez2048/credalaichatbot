# P7-002 — Messaging adapter + inbound webhook contract (Twilio-first, OpenClaw-ready)

**Priority:** P7  
**Estimate:** 5 hours  
**Phase:** 7 — Omnichannel Continuity  
**Status:** Proposed

---

## Goal

Build a provider-agnostic messaging interface with a Twilio-backed demo implementation first, so outbound reminders and inbound SMS replies are processed safely and idempotently while keeping OpenClaw-compatible boundaries.

---

## Deliverables Checklist

- [x] `Messaging::Provider` interface
- [x] `Messaging::TwilioAdapter` implementation for live demo
- [ ] `Messaging::OpenClawAdapter` — deferred; architecture doc + factory pattern keeps slot open. **Integration guide:** [`docs/guides/openclaw-integration.md`](../guides/openclaw-integration.md)
- [x] Inbound webhook endpoint with signature verification — `POST /webhooks/sms/twilio`
- [x] Idempotency for inbound message events — `SmsEvent` unique on provider/direction/external_id
- [x] Outbound send API — `TwilioAdapter#send_message`, used by inbound processor + handoff API
- [ ] Retry + timeout policy at provider boundary — follow-up
- [x] Tests for adapter and webhook verification
- [x] Demo-mode fallback — `SMS_PROVIDER=mock` + `MockAdapter`

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | Outbound SMS sends through adapter | Unit test with mocked provider response |
| 2 | Inbound webhook creates user turn | Integration test for webhook payload |
| 3 | Duplicate webhook events are ignored | Idempotency test |
| 4 | Invalid signature is rejected | Request spec returns unauthorized |
| 5 | Live demo path works with one provider only | Manual test with Twilio test number |

---

## Definition of Done

- [ ] Deliverables complete
- [ ] Tests pass
- [ ] `DEVLOG.md` updated
- [ ] Feature branch pushed; PR ready
