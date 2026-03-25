# frozen_string_literal: true

module Scheduling
  class SlotRecommender
    DEFAULT_LIMIT = 5

    class << self
      # Recommend slots sorted by availability (most remaining capacity first, then soonest)
      def recommend(service_type: nil, date_from: nil, date_to: nil, limit: DEFAULT_LIMIT)
        slots = SlotManager.list_available(
          service_type: service_type,
          date_from: date_from,
          date_to: date_to
        )

        # Score: remaining capacity (higher is better), then soonest date
        slots.sort_by { |s| [-(s.capacity - s.booked_count), s.date, s.start_time] }
             .first(limit)
      end

      # Format slots for inclusion in LLM tool response
      def format_for_llm(slots)
        slots.map do |s|
          {
            slot_id: s.id,
            date: s.date.to_s,
            start_time: s.start_time.strftime("%H:%M"),
            end_time: s.end_time.strftime("%H:%M"),
            service_type: s.service_type,
            spots_remaining: s.capacity - s.booked_count
          }
        end
      end
    end
  end
end
