# P4-003 — Progress milestones & encouragement

**Priority:** P4
**Estimate:** 2 hours
**Phase:** 4 — Emotional Support
**Status:** Not started

---

## Goal

Celebrate the user's progress through onboarding by recognizing step completions, acknowledging milestones (25%, 50%, 75%, 100%), and providing encouragement messages. The system tracks which steps have been completed, injects milestone awareness into the system prompt, and triggers celebration messages at key progress points. This keeps users motivated through a potentially tedious multi-step process.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P4-003 |
|--------|----------------------|
| **P1-002** | Orchestrator with step tracking, `OnboardingSession#progress_percent`, `saveOnboardingProgress` tool |
| **P4-002** | Sentiment-aware prompting (encouragement tone adapts to sentiment) |

---

## Deliverables Checklist

- [ ] `Onboarding::MilestoneTracker` — tracks step completions, calculates progress percentage, determines if a milestone was just crossed
- [ ] `config/prompts/milestones.yml` — milestone definitions (thresholds, celebration messages, next-step previews)
- [ ] `Onboarding::EncouragementGenerator` — selects encouragement message based on milestone, step, and current sentiment
- [ ] Update `Onboarding::Orchestrator` to check for milestones after each step transition and inject celebration context
- [ ] Update system prompt instructions: when a milestone is crossed, the LLM should naturally celebrate before continuing
- [ ] Progress indicator data exposed to frontend: `progress_percent`, `completed_steps`, `total_steps` (via Action Cable broadcast or API)
- [ ] Frontend progress bar component (minimal — a Tailwind-styled bar at the top of the chat, updated via Action Cable)
- [ ] Unit tests for MilestoneTracker (threshold detection, progress calculation)
- [ ] Unit tests for EncouragementGenerator (correct message selection per milestone + sentiment)
- [ ] Integration test: complete a step → milestone detected → celebration message appears in chat

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | Progress percentage updates when a step is completed | Unit test: complete personal_info step, assert progress_percent updated |
| 2 | Milestone crossed at 25%, 50%, 75%, 100% thresholds | Unit test: set progress to 24% → no milestone; set to 25% → milestone triggered |
| 3 | Celebration message is contextual to the milestone | Unit test: 50% milestone returns mid-point celebration message |
| 4 | Encouragement adapts to sentiment (frustrated user gets warmer message) | Unit test: frustrated + 50% milestone → empathetic celebration |
| 5 | LLM naturally incorporates celebration in its response | Integration test: complete step crossing 50%, observe celebration in assistant message |
| 6 | Frontend progress bar reflects current progress | Manual test: progress bar updates as steps complete |
| 7 | 100% completion triggers a distinct congratulation flow | Unit test: complete final step, assert complete milestone and congratulation message |

---

## Architecture

### New files

| File | Purpose |
|------|---------|
| `app/services/onboarding/milestone_tracker.rb` | Progress tracking and milestone detection |
| `app/services/onboarding/encouragement_generator.rb` | Message selection based on milestone + sentiment |
| `config/prompts/milestones.yml` | Milestone definitions and message templates |
| `app/javascript/components/ProgressBar.jsx` | Tailwind progress bar component |
| `test/unit/onboarding/milestone_tracker_test.rb` | Tracker tests |
| `test/unit/onboarding/encouragement_generator_test.rb` | Generator tests |

### Modified files

| File | Changes |
|------|---------|
| `app/services/onboarding/orchestrator.rb` | Check milestones after step transitions, inject celebration context |
| `app/channels/onboarding_chat_channel.rb` | Broadcast progress updates to frontend |
| `app/javascript/components/ChatApp.jsx` | Render ProgressBar, subscribe to progress updates |

### Milestone config

```yaml
# config/prompts/milestones.yml

step_weights:
  welcome: 5
  personal_info: 25
  document_upload: 30
  scheduling: 25
  review: 10
  complete: 5

milestones:
  - threshold: 25
    label: "Getting Started"
    celebration: "Great start! You've completed the first part of your onboarding."
    next_preview: "Next up, we'll handle some paperwork."
  - threshold: 50
    label: "Halfway There"
    celebration: "You're halfway through! The hardest parts are behind you."
    next_preview: "We'll get your appointments scheduled next."
  - threshold: 75
    label: "Almost Done"
    celebration: "You're in the home stretch — just a few more things to wrap up!"
    next_preview: "We'll review everything and make sure it all looks good."
  - threshold: 100
    label: "All Done"
    celebration: "Congratulations! You've completed your onboarding. Welcome to the team!"
    next_preview: ""

sentiment_overrides:
  frustrated:
    prefix: "I know this has been a lot — "
    suffix: " You're doing really well."
  anxious:
    prefix: "You're making excellent progress — "
    suffix: " Everything is looking great so far."
  confused:
    prefix: ""
    suffix: " If anything is unclear, just let me know and we can revisit it."
```

### MilestoneTracker

```ruby
module Onboarding
  class MilestoneTracker
    THRESHOLDS = [25, 50, 75, 100].freeze

    def initialize(session)
      @session = session
    end

    def step_completed!(step_name)
      old_percent = @session.progress_percent
      new_percent = calculate_progress
      @session.update!(progress_percent: new_percent)

      crossed = THRESHOLDS.select { |t| old_percent < t && new_percent >= t }
      crossed.map { |t| milestone_for(t) }
    end

    def calculate_progress
      weights = load_config["step_weights"]
      completed = @session.metadata["completed_steps"] || []
      completed.sum { |step| weights[step] || 0 }
    end

    private

    def milestone_for(threshold)
      milestones = load_config["milestones"]
      milestones.find { |m| m["threshold"] == threshold }
    end
  end
end
```

### EncouragementGenerator

```ruby
module Onboarding
  class EncouragementGenerator
    def generate(milestone, sentiment_label: "neutral")
      base = milestone["celebration"]
      overrides = load_config.dig("sentiment_overrides", sentiment_label)

      if overrides
        "#{overrides['prefix']}#{base.downcase}#{overrides['suffix']}"
      else
        base
      end
    end
  end
end
```

### Orchestrator integration

```ruby
# After step transition in Orchestrator:
def after_step_transition(session, completed_step)
  tracker = MilestoneTracker.new(session)
  milestones = tracker.step_completed!(completed_step)

  return if milestones.empty?

  sentiment = session.sentiment_readings.order(created_at: :desc).first&.label || "neutral"
  generator = EncouragementGenerator.new

  celebration_context = milestones.map { |m|
    generator.generate(m, sentiment_label: sentiment)
  }.join(" ")

  # Inject into next LLM call context
  @celebration_context = celebration_context

  # Broadcast progress to frontend
  broadcast_progress(session)
end
```

### Frontend ProgressBar

```jsx
function ProgressBar({ percent, label }) {
  return (
    <div className="w-full bg-gray-200 rounded-full h-2.5 mb-4">
      <div
        className="bg-blue-600 h-2.5 rounded-full transition-all duration-500"
        style={{ width: `${percent}%` }}
      />
      <p className="text-xs text-gray-500 mt-1">{label || `${percent}% complete`}</p>
    </div>
  );
}
```

---

## Files You Should READ Before Coding

1. `app/services/onboarding/orchestrator.rb` — step transition logic
2. `app/models/onboarding_session.rb` — `progress_percent`, `metadata`, `current_step`
3. `config/prompts/onboarding_steps.yml` — step definitions and ordering
4. `config/prompts/sentiment_adaptations.yml` — P4-002 sentiment config pattern
5. `app/channels/onboarding_chat_channel.rb` — Action Cable broadcasting pattern
6. `app/javascript/components/ChatApp.jsx` — where to add ProgressBar

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All acceptance criteria verified
- [ ] `DEVLOG.md` updated with P4-003 entry
- [ ] Feature branch pushed; PR ready for review

---

## Suggested Branch

```bash
git switch -c feature/P4-003-progress-milestones
```

---

## Out of Scope for P4-003

- Escalation to human agents (P4-004)
- Gamification / badges / rewards (future)
- Admin analytics on completion rates (P5-004)
- Email reminders for incomplete onboarding (future)
