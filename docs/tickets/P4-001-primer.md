# P4-001 — Sentiment analysis integration

**Priority:** P4
**Estimate:** 3 hours
**Phase:** 4 — Emotional Support
**Status:** Not started

---

## Goal

Wire the `detectUserSentiment` tool to a real implementation that analyzes the user's recent message history for emotional signals (frustration, confusion, anxiety, satisfaction, neutrality). The system uses the LLM itself to perform sentiment classification on a sliding window of messages, returning a structured sentiment result with label, confidence score, and detected signals. Results are persisted per session for trend tracking and consumed by P4-002 (adaptive behavior) and P4-004 (escalation).

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P4-001 |
|--------|----------------------|
| **P0-003** | `Tools::Router`, `detectUserSentiment` tool definition, `LLM::ChatService` |
| **P1-001** | Message persistence (need message history to analyze) |
| **P1-002** | Orchestrator that can trigger tool calls within the conversation flow |

---

## Deliverables Checklist

- [ ] `Sentiment::Analyzer` service — takes an array of recent messages, sends them to the LLM with a sentiment classification prompt, returns structured result
- [ ] Sentiment classification prompt in `config/prompts/sentiment_analysis.yml` — instructs the LLM to classify into: `positive`, `neutral`, `confused`, `frustrated`, `anxious`; return confidence 0.0-1.0 and up to 3 signal phrases
- [ ] `Tools::Handlers::DetectUserSentiment` — real handler replacing stub; calls `Sentiment::Analyzer`, returns result
- [ ] Migration: `create_sentiment_readings` table (onboarding_session_id, label, confidence, signals, message_window_start_id, message_window_end_id, timestamps)
- [ ] `SentimentReading` model — belongs_to :onboarding_session, stores analysis results
- [ ] `Sentiment::Tracker` — persists readings, provides trend queries (e.g., `recent_trend(session_id, last_n)`, `is_escalating?(session_id)`)
- [ ] Automatic sentiment check: after every N messages (configurable, default 3), the Orchestrator triggers a background sentiment check
- [ ] Update `Tools::Router` to map `detectUserSentiment` to real handler
- [ ] Unit tests for Analyzer (mock LLM response, assert parsing of structured result)
- [ ] Unit tests for Tracker (persist reading, query trend, detect escalation)
- [ ] Unit tests for DetectUserSentiment handler
- [ ] Integration test: send messages with frustrated tone → sentiment detected as frustrated

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | `detectUserSentiment` tool returns structured sentiment data | Unit test: call handler with message history, assert label + confidence + signals in response |
| 2 | Sentiment classified into one of 5 labels with confidence score | Unit test: mock LLM response, assert valid label and confidence 0.0-1.0 |
| 3 | Sentiment readings are persisted to the database | Unit test: run analyzer, assert SentimentReading created |
| 4 | Tracker detects escalating frustration across multiple readings | Unit test: create sequence of readings (neutral → confused → frustrated), assert is_escalating? returns true |
| 5 | Automatic sentiment check triggers every N messages | Unit test: send N messages through Orchestrator, assert sentiment check was triggered |
| 6 | Sentiment prompt returns parseable JSON from the LLM | Integration test: send real messages to LLM with sentiment prompt, assert valid JSON response |

---

## Architecture

### New files

| File | Purpose |
|------|---------|
| `app/services/sentiment/analyzer.rb` | LLM-based sentiment classification |
| `app/services/sentiment/tracker.rb` | Persist and query sentiment readings |
| `app/services/tools/handlers/detect_user_sentiment.rb` | Real tool handler |
| `app/models/sentiment_reading.rb` | ActiveRecord model |
| `db/migrate/XXXX_create_sentiment_readings.rb` | Sentiment readings table |
| `config/prompts/sentiment_analysis.yml` | Sentiment classification prompt |
| `test/unit/sentiment/analyzer_test.rb` | Analyzer tests |
| `test/unit/sentiment/tracker_test.rb` | Tracker tests |
| `test/unit/tools/handlers/detect_user_sentiment_test.rb` | Handler tests |
| `test/models/sentiment_reading_test.rb` | Model tests |

### Modified files

| File | Changes |
|------|---------|
| `app/services/tools/router.rb` | Map `detectUserSentiment` to real handler |
| `app/services/onboarding/orchestrator.rb` | Add automatic sentiment check after every N messages |
| `app/models/onboarding_session.rb` | Add `has_many :sentiment_readings` |

### Schema: `sentiment_readings`

```ruby
create_table :sentiment_readings do |t|
  t.references :onboarding_session, null: false, foreign_key: true
  t.string     :label,              null: false  # positive, neutral, confused, frustrated, anxious
  t.decimal    :confidence,         precision: 5, scale: 4, null: false
  t.jsonb      :signals,            default: []  # array of detected signal phrases
  t.bigint     :message_window_start_id
  t.bigint     :message_window_end_id
  t.timestamps
end

add_index :sentiment_readings, [:onboarding_session_id, :created_at]
```

### Sentiment::Analyzer

```ruby
module Sentiment
  class Analyzer
    WINDOW_SIZE = 5  # analyze last 5 messages

    def analyze(messages)
      recent = messages.last(WINDOW_SIZE)
      return default_result if recent.empty?

      prompt = load_prompt("sentiment_analysis")
      formatted_messages = recent.map { |m| "#{m[:role]}: #{m[:content]}" }.join("\n")

      response = LLM::ChatService.new.chat(
        messages: [
          { role: "system", content: prompt },
          { role: "user", content: formatted_messages }
        ],
        response_format: { type: "json_object" }
      )

      parse_result(response)
    end

    private

    def parse_result(response)
      json = JSON.parse(response.dig("choices", 0, "message", "content"))
      {
        label: json["label"],
        confidence: json["confidence"].to_f,
        signals: json["signals"] || []
      }
    rescue JSON::ParserError
      default_result
    end

    def default_result
      { label: "neutral", confidence: 0.5, signals: [] }
    end
  end
end
```

### Sentiment classification prompt

```yaml
system_prompt: |
  You are a sentiment analysis system. Analyze the following conversation messages
  and classify the user's current emotional state.

  Respond with JSON only:
  {
    "label": "positive|neutral|confused|frustrated|anxious",
    "confidence": 0.0-1.0,
    "signals": ["up to 3 short phrases that indicate the detected sentiment"]
  }

  Classification guidelines:
  - "frustrated": user expresses annoyance, repeats questions, uses negative language about the process
  - "confused": user asks for clarification repeatedly, says "I don't understand", gives unrelated answers
  - "anxious": user expresses worry about deadlines, correctness, or consequences
  - "positive": user is engaged, cooperative, expresses satisfaction or gratitude
  - "neutral": no strong emotional signal detected

  Focus on the USER messages. Assistant messages provide context only.
```

### Automatic trigger in Orchestrator

```ruby
# In Onboarding::Orchestrator#process, after persisting assistant response:
if should_check_sentiment?(session)
  Sentiment::Analyzer.new.analyze_async(session)
end

def should_check_sentiment?(session)
  message_count = session.messages.where(role: "user").count
  interval = ENV.fetch("SENTIMENT_CHECK_INTERVAL", 3).to_i
  message_count > 0 && (message_count % interval).zero?
end
```

---

## Files You Should READ Before Coding

1. `config/prompts/tool_definitions.yml` — `detectUserSentiment` schema
2. `app/services/tools/router.rb` — stub handler pattern
3. `app/services/llm/chat_service.rb` — how to call the LLM
4. `app/services/onboarding/orchestrator.rb` — where to hook automatic checks
5. `app/models/onboarding_session.rb` — session model associations
6. `db/schema.rb` — existing tables and patterns

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All acceptance criteria verified
- [ ] `DEVLOG.md` updated with P4-001 entry
- [ ] Feature branch pushed; PR ready for review

---

## Suggested Branch

```bash
git switch -c feature/P4-001-sentiment-analysis
```

---

## Out of Scope for P4-001

- Adapting chatbot behavior based on sentiment (P4-002)
- Progress milestones and encouragement (P4-003)
- Escalation to human agents (P4-004)
- Real-time sentiment display in admin dashboard (P5-004)
- Client-side sentiment indicators (future)
