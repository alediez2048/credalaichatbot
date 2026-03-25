# P3-004 — Rescheduling flow

**Priority:** P3
**Estimate:** 2.5 hours
**Phase:** 3 — Scheduling
**Status:** Not started

---

## Goal

Allow users to reschedule or cancel booked appointments through the chatbot. When a user says "I need to reschedule" or "cancel my appointment," the LLM detects the intent, looks up their current booking, presents it for confirmation, then either cancels it outright or guides them through picking a new slot (cancel + rebook). The flow reuses the slot recommendation from P3-002 and the confirmation pipeline from P3-003.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P3-004 |
|--------|----------------------|
| **P3-001** | `AppointmentSlot` model with `booked_count` decrement on cancel |
| **P3-002** | `getAvailableSlots` and `bookAppointment` tool handlers |
| **P3-003** | `ConfirmationService` for re-booking confirmation + updated calendar event |
| **P1-002** | Orchestrator handles multi-turn tool call sequences |

---

## Deliverables Checklist

- [ ] New tool definition: `cancelAppointment` in `config/prompts/tool_definitions.yml` — params: `bookingId`, optional `reason`
- [ ] New tool definition: `getMyBookings` in `config/prompts/tool_definitions.yml` — params: none (uses session context)
- [ ] `Tools::Handlers::CancelAppointment` — cancels booking, decrements slot `booked_count`, sets booking status to "cancelled"
- [ ] `Tools::Handlers::GetMyBookings` — returns active bookings for the current session
- [ ] `Scheduling::SlotManager#cancel!(booking_id)` — atomically decrements `booked_count`, sets booking status, records cancellation reason
- [ ] `Scheduling::ReschedulingService` — orchestrates cancel + rebook: validates cancellation window, cancels old booking, triggers new booking flow
- [ ] Migration: add `cancelled_at`, `cancellation_reason`, `rescheduled_from_id` columns to `bookings`
- [ ] Cancellation policy: bookings can only be cancelled/rescheduled at least 2 hours before `starts_at` (configurable)
- [ ] Update prompt instructions: LLM recognizes reschedule/cancel intent, calls `getMyBookings` first, confirms with user, then proceeds
- [ ] Update `Tools::Router` to register new handlers
- [ ] Send cancellation email via `BookingConfirmationMailer#cancellation_email(booking)`
- [ ] Send updated confirmation email on rebook (reuse P3-003 ConfirmationService)
- [ ] Unit tests for CancelAppointment handler (success, already cancelled, too late to cancel)
- [ ] Unit tests for GetMyBookings handler
- [ ] Unit tests for SlotManager#cancel! (atomic decrement, status update)
- [ ] Unit tests for ReschedulingService (cancel + rebook, cancellation window enforcement)
- [ ] Integration test: reschedule flow end-to-end (view booking → cancel → pick new slot → confirm)

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | User can view their current bookings via chat | Unit test: call GetMyBookings handler, assert active bookings returned |
| 2 | User can cancel a booking through the chatbot | Unit test: cancel booking, assert status = "cancelled", booked_count decremented |
| 3 | Cancellation within 2 hours of start time is rejected | Unit test: attempt cancel on imminent booking, assert error |
| 4 | User can reschedule: old booking cancelled, new one created | Integration test: reschedule flow, assert old cancelled + new confirmed |
| 5 | Rescheduled booking links back to original via `rescheduled_from_id` | Unit test: rebook, assert rescheduled_from_id points to old booking |
| 6 | Cancellation email is sent on cancel | Unit test: cancel booking, assert mailer delivers cancellation email |
| 7 | New confirmation email + .ics sent on rebook | Unit test: rebook, assert new confirmation email sent |
| 8 | Slot capacity is correctly restored on cancellation | Unit test: book (count=1), cancel (count=0), book again (count=1) |

---

## Architecture

### New files

| File | Purpose |
|------|---------|
| `app/services/tools/handlers/cancel_appointment.rb` | Cancel booking tool handler |
| `app/services/tools/handlers/get_my_bookings.rb` | List user's active bookings |
| `app/services/scheduling/rescheduling_service.rb` | Cancel + rebook orchestration |
| `db/migrate/XXXX_add_cancellation_fields_to_bookings.rb` | cancelled_at, cancellation_reason, rescheduled_from_id |
| `app/views/booking_confirmation_mailer/cancellation_email.html.erb` | HTML cancellation email |
| `app/views/booking_confirmation_mailer/cancellation_email.text.erb` | Text cancellation email |
| `test/unit/tools/handlers/cancel_appointment_test.rb` | Handler tests |
| `test/unit/tools/handlers/get_my_bookings_test.rb` | Handler tests |
| `test/unit/scheduling/rescheduling_service_test.rb` | Service tests |

### Modified files

| File | Changes |
|------|---------|
| `config/prompts/tool_definitions.yml` | Add `cancelAppointment` and `getMyBookings` tool definitions |
| `app/services/tools/router.rb` | Register new handlers |
| `app/services/scheduling/slot_manager.rb` | Add `cancel!(booking_id)` method |
| `app/mailers/booking_confirmation_mailer.rb` | Add `cancellation_email` method |
| `config/prompts/onboarding_steps.yml` | Update scheduling step with reschedule/cancel instructions |

### New tool definitions

```yaml
- name: cancelAppointment
  description: Cancel an existing appointment booking.
  parameters:
    type: object
    properties:
      bookingId:
        type: string
        description: ID of the booking to cancel.
      reason:
        type: string
        description: Optional reason for cancellation.
    required:
      - bookingId

- name: getMyBookings
  description: Retrieve the user's active (non-cancelled) bookings for the current session.
  parameters:
    type: object
    properties: {}
    required: []
```

### Cancellation flow

1. User says "I need to reschedule my appointment"
2. LLM calls `getMyBookings` → returns list of active bookings
3. LLM presents bookings and asks which one to reschedule (or auto-selects if only one)
4. User confirms → LLM calls `cancelAppointment` with bookingId
5. Handler checks cancellation window (>= 2 hours before starts_at)
6. Atomically: set booking status = "cancelled", decrement slot booked_count, set cancelled_at
7. Send cancellation email
8. LLM then asks about new time preferences → calls `getAvailableSlots` → `bookAppointment` (reusing P3-002 flow)
9. New booking gets `rescheduled_from_id` pointing to the old booking
10. P3-003 ConfirmationService sends new confirmation + calendar

### Atomic cancellation

```ruby
def cancel!(booking_id, reason: nil)
  Booking.transaction do
    booking = Booking.lock.find(booking_id)
    raise AlreadyCancelledError if booking.status == "cancelled"
    raise TooLateToCancelError if booking.starts_at < Time.current + cancellation_window

    booking.update!(
      status: "cancelled",
      cancelled_at: Time.current,
      cancellation_reason: reason
    )

    if booking.appointment_slot.present?
      booking.appointment_slot.lock!
      booking.appointment_slot.decrement!(:booked_count)
    end

    booking
  end
end

def cancellation_window
  (ENV.fetch("CANCELLATION_WINDOW_HOURS", 2).to_i).hours
end
```

---

## Files You Should READ Before Coding

1. `app/services/scheduling/slot_manager.rb` — add cancel! method here
2. `app/services/tools/handlers/book_appointment.rb` — pattern for booking handler
3. `app/services/scheduling/confirmation_service.rb` — reuse for rebook confirmation
4. `app/mailers/booking_confirmation_mailer.rb` — add cancellation_email
5. `config/prompts/tool_definitions.yml` — add new tool definitions
6. `db/schema.rb` — bookings table structure

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All acceptance criteria verified
- [ ] `DEVLOG.md` updated with P3-004 entry
- [ ] Feature branch pushed; PR ready for review

---

## Suggested Branch

```bash
git switch -c feature/P3-004-rescheduling-flow
```

---

## Out of Scope for P3-004

- Recurring appointment management (future)
- Waitlist when preferred slots are full (future)
- Admin-initiated rescheduling (future)
- Penalty or fee for late cancellation (future)
