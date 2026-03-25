# frozen_string_literal: true

# P0-005: LangSmith observability. No-op when LANGSMITH_API_KEY is blank.
# No gem required — uses Net::HTTP to POST runs to the LangSmith REST API.
