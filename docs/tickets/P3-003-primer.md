# P3-003 — Booking confirmation & calendar event

**Priority:** P3
**Estimate:** 3 hours
**Phase:** 3 — Scheduling
**Status:** Not started

---

## Goal

After a user books an appointment through the chatbot (P3-002), generate a confirmation with full details, create a downloadable `.ics` calendar file, and send a confirmation email. The chat displays the confirmation inline with a download link for the calendar event. The email includes the same details plus the `.ics` as an attachment.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P3-003 |
|--------|----------------------|
| **P3-001** | `AppointmentSlot` and `Booking` models |
| **P3-002** | `bookAppointment` tool handler creates real bookings |
| **P0-001** | Rails app with Action Mailer configured |

---

## Deliverables Checklist

- [ ] `Scheduling::CalendarGenerator` — generates `.ics` (iCalendar RFC 5545) file content from a Booking record
- [ ] `Scheduling::ConfirmationService` — orchestrates post-booking: generates calendar file, triggers email, returns confirmation data for chat
- [ ] `BookingConfirmationMailer` — Action Mailer class with `confirmation_email(booking)` method; HTML + text templates
- [ ] `.ics` file served via a controller endpoint (`GET /bookings/:id/calendar.ics`) with proper `text/calendar` content type
- [ ] Update `Tools::Handlers::BookAppointment` to call `ConfirmationService` after successful booking and return confirmation + calendar URL in tool result
- [ ] Chat displays confirmation card: date, time, service type, duration, calendar download link
- [ ] Migration: add `confirmation_sent_at` and `calendar_token` columns to `bookings` (token for secure .ics download)
- [ ] Unit tests for CalendarGenerator (valid .ics output with correct VEVENT fields)
- [ ] Unit tests for ConfirmationService (triggers mailer, generates calendar, returns data)
- [ ] Unit tests for BookingConfirmationMailer (email content, .ics attachment)
- [ ] Controller test for calendar download endpoint (valid token → .ics, invalid → 404)

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | Booking creates a valid `.ics` file with correct date, time, duration, and title | Unit test: generate .ics, parse it, assert VEVENT fields match booking |
| 2 | `.ics` file is downloadable via `/bookings/:id/calendar.ics?token=X` | Controller test: request with valid token → 200 + text/calendar content type |
| 3 | Confirmation email is sent after booking with .ics attachment | Unit test: assert mail delivered, has attachment with .ics content type |
| 4 | Email contains booking details: date, time, service type, location | Unit test: assert email body includes expected fields |
| 5 | Chat displays confirmation with booking details and calendar download link | Manual test: complete booking → see confirmation card in chat |
| 6 | Invalid or missing calendar token returns 404 | Controller test: bad token → 404 |
| 7 | `confirmation_sent_at` is set after email delivery | Unit test: after ConfirmationService runs, booking.confirmation_sent_at is present |

---

## Architecture

### New files

| File | Purpose |
|------|---------|
| `app/services/scheduling/calendar_generator.rb` | Generates RFC 5545 .ics content |
| `app/services/scheduling/confirmation_service.rb` | Post-booking orchestration |
| `app/mailers/booking_confirmation_mailer.rb` | Action Mailer for confirmation email |
| `app/views/booking_confirmation_mailer/confirmation_email.html.erb` | HTML email template |
| `app/views/booking_confirmation_mailer/confirmation_email.text.erb` | Plain text email template |
| `app/controllers/bookings_controller.rb` | Calendar download endpoint |
| `db/migrate/XXXX_add_confirmation_fields_to_bookings.rb` | Add confirmation_sent_at, calendar_token |
| `test/unit/scheduling/calendar_generator_test.rb` | .ics generation tests |
| `test/unit/scheduling/confirmation_service_test.rb` | Service tests |
| `test/mailers/booking_confirmation_mailer_test.rb` | Mailer tests |
| `test/controllers/bookings_controller_test.rb` | Calendar download tests |

### Modified files

| File | Changes |
|------|---------|
| `app/services/tools/handlers/book_appointment.rb` | Call ConfirmationService after booking, include calendar URL in result |
| `config/routes.rb` | Add `GET /bookings/:id/calendar` route |
| `app/models/booking.rb` | Add `before_create :generate_calendar_token` callback |

### CalendarGenerator output

```ruby
module Scheduling
  class CalendarGenerator
    def generate(booking)
      <<~ICS
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Credal//Onboarding//EN
        BEGIN:VEVENT
        DTSTART:#{format_datetime(booking.starts_at)}
        DTEND:#{format_datetime(booking.starts_at + booking.duration_minutes.minutes)}
        SUMMARY:#{booking.service_type.titleize} — Credal Onboarding
        DESCRIPTION:Your #{booking.service_type.titleize} appointment for employee onboarding.
        STATUS:CONFIRMED
        UID:#{booking.calendar_token}@credal.ai
        END:VEVENT
        END:VCALENDAR
      ICS
    end

    private

    def format_datetime(dt)
      dt.utc.strftime("%Y%m%dT%H%M%SZ")
    end
  end
end
```

### ConfirmationService flow

1. Generate `calendar_token` (SecureRandom.urlsafe_base64) if not present
2. Generate `.ics` content via `CalendarGenerator`
3. Send email via `BookingConfirmationMailer.confirmation_email(booking).deliver_later`
4. Update `booking.confirmation_sent_at`
5. Return hash with confirmation details + calendar download URL for chat display

### Secure calendar download

```ruby
class BookingsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:calendar]

  def calendar
    booking = Booking.find_by!(id: params[:id], calendar_token: params[:token])
    ics = Scheduling::CalendarGenerator.new.generate(booking)
    send_data ics,
      filename: "credal-appointment-#{booking.id}.ics",
      type: "text/calendar",
      disposition: "attachment"
  end
end
```

---

## Files You Should READ Before Coding

1. `app/services/tools/handlers/book_appointment.rb` — current handler (P3-002)
2. `app/models/booking.rb` — model associations and columns
3. `db/schema.rb` — bookings table structure
4. `config/routes.rb` — existing routes
5. `config/environments/development.rb` — Action Mailer config

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All acceptance criteria verified
- [ ] `DEVLOG.md` updated with P3-003 entry
- [ ] Feature branch pushed; PR ready for review

---

## Suggested Branch

```bash
git switch -c feature/P3-003-booking-confirmation-calendar
```

---

## Out of Scope for P3-003

- Rescheduling or cancellation (P3-004)
- Google Calendar / Outlook integration (future — .ics file is portable)
- SMS notifications (future)
- Recurring appointments (future)
