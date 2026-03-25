# P3-001 — Appointment slot management

**Priority:** P3
**Estimate:** 3 hours
**Phase:** 3 — Scheduling
**Status:** Not started

---

## Goal

Build the admin-facing appointment slot management system. Admins define available time slots (date, start time, duration, service type, capacity) and the system exposes them for querying. The existing `bookings` table (already in schema) stores confirmed bookings; this ticket adds an `appointment_slots` table for the supply side and CRUD operations so slots can be created, listed, updated, and soft-deleted. A service layer provides the query interface that P3-002 will wire into the `getAvailableSlots` tool.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P3-001 |
|--------|----------------------|
| **P0-001** | Rails app, DB, `OnboardingSession`, `Booking` model must exist |
| **P0-003** | Tool definitions YAML (defines `getAvailableSlots` and `bookAppointment` schemas) |

P1-002 (orchestration) is helpful but not a hard blocker — slot management is backend-only.

---

## Deliverables Checklist

- [ ] Migration: `create_appointment_slots` table (date, start_time, end_time, duration_minutes, service_type, capacity, booked_count, status, created_by, metadata)
- [ ] `AppointmentSlot` model with validations (start < end, capacity > 0, no overlapping slots for same service_type)
- [ ] `Booking` model updated: add `appointment_slot_id` foreign key, belongs_to :appointment_slot (optional for backward compat)
- [ ] `Scheduling::SlotManager` service — `create_slot`, `list_available(date_range, service_type)`, `update_slot`, `cancel_slot`
- [ ] `SlotManager#list_available` returns only slots where `booked_count < capacity` and `status = "available"` and `starts_at > Time.current`
- [ ] `SlotManager#book!(slot_id, onboarding_session_id)` — atomically increments `booked_count`, creates `Booking`, raises if full
- [ ] Seed data: sample slots for the next 2 weeks (Mon-Fri, 9am-5pm, 30-min intervals, service types: "orientation", "hr_review", "it_setup")
- [ ] Unit tests for SlotManager (create, list with filters, book, double-book rejection, cancel)
- [ ] Unit tests for AppointmentSlot model validations

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | Appointment slots can be created with date, time, service type, capacity | Unit test: create slot, verify persisted |
| 2 | `list_available` returns only future, non-full, active slots | Unit test: mix of full/past/cancelled slots, assert only valid ones returned |
| 3 | `list_available` filters by date range and service type | Unit test: pass date range + service_type, assert correct subset |
| 4 | Booking a slot atomically increments booked_count and creates Booking record | Unit test: book slot, assert booked_count + 1, Booking exists |
| 5 | Booking a full slot raises an error | Unit test: fill slot to capacity, attempt one more, assert raises |
| 6 | Overlapping slots for same service_type are rejected | Unit test: create overlapping slot, assert validation error |
| 7 | Seed data creates usable slots | Run `db:seed`, query slots, verify populated |

---

## Architecture

### New files

| File | Purpose |
|------|---------|
| `db/migrate/XXXX_create_appointment_slots.rb` | Slots table migration |
| `db/migrate/XXXX_add_appointment_slot_id_to_bookings.rb` | FK on bookings |
| `app/models/appointment_slot.rb` | Model with validations and scopes |
| `app/services/scheduling/slot_manager.rb` | CRUD + availability queries + atomic booking |
| `db/seeds/appointment_slots.rb` | Seed data (require from `db/seeds.rb`) |
| `test/models/appointment_slot_test.rb` | Model unit tests |
| `test/unit/scheduling/slot_manager_test.rb` | Service unit tests |

### Modified files

| File | Changes |
|------|---------|
| `app/models/booking.rb` | Add `belongs_to :appointment_slot, optional: true` |
| `app/models/appointment_slot.rb` | `has_many :bookings` |
| `db/seeds.rb` | Require appointment_slots seed |

### Schema: `appointment_slots`

```ruby
create_table :appointment_slots do |t|
  t.date     :date,             null: false
  t.time     :start_time,       null: false
  t.time     :end_time,         null: false
  t.integer  :duration_minutes, null: false, default: 30
  t.string   :service_type,     null: false
  t.integer  :capacity,         null: false, default: 1
  t.integer  :booked_count,     null: false, default: 0
  t.string   :status,           null: false, default: "available"
  t.bigint   :created_by
  t.jsonb    :metadata,         default: {}
  t.timestamps
end

add_index :appointment_slots, [:date, :service_type]
add_index :appointment_slots, [:date, :start_time, :service_type], unique: true
```

### Atomic booking pattern

```ruby
def book!(slot_id, onboarding_session_id, service_type: nil)
  AppointmentSlot.transaction do
    slot = AppointmentSlot.lock.find(slot_id)
    raise SlotFullError if slot.booked_count >= slot.capacity

    slot.increment!(:booked_count)
    Booking.create!(
      appointment_slot: slot,
      onboarding_session_id: onboarding_session_id,
      starts_at: DateTime.new(slot.date.year, slot.date.month, slot.date.day, slot.start_time.hour, slot.start_time.min),
      duration_minutes: slot.duration_minutes,
      service_type: service_type || slot.service_type,
      status: "confirmed"
    )
  end
end
```

---

## Files You Should READ Before Coding

1. `db/schema.rb` — existing `bookings` table structure
2. `app/models/booking.rb` — current model (if exists)
3. `config/prompts/tool_definitions.yml` — `getAvailableSlots` and `bookAppointment` parameter shapes
4. `app/services/tools/router.rb` — where tool handlers are mapped (P3-002 will wire these)

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All acceptance criteria verified
- [ ] `DEVLOG.md` updated with P3-001 entry
- [ ] Feature branch pushed; PR ready for review

---

## Suggested Branch

```bash
git switch -c feature/P3-001-appointment-slot-management
```

---

## Out of Scope for P3-001

- AI-powered slot recommendation (P3-002)
- Calendar event generation / email confirmation (P3-003)
- Rescheduling flow (P3-004)
- Admin UI for slot management (future — this is service-layer + seeds only)
- Wiring `getAvailableSlots` tool handler to real data (P3-002)
