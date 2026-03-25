# frozen_string_literal: true

module Onboarding
  class MilestoneTracker
    MILESTONES = [25, 50, 75, 100].freeze

    MESSAGES = {
      25 => "You're a quarter of the way through onboarding! Great progress so far.",
      50 => "Halfway there! You're doing great — just a few more steps to go.",
      75 => "Three-quarters done! Almost at the finish line.",
      100 => "Onboarding complete! Congratulations on finishing all the steps."
    }.freeze

    class << self
      def milestone_reached?(session, threshold)
        (session.progress_percent || 0) >= threshold
      end

      def encouragement_for(milestone)
        MESSAGES[milestone] || "Keep going — you're making great progress!"
      end

      # Returns milestones that have been crossed but not yet acknowledged
      def check_milestones(session)
        progress = session.progress_percent || 0
        seen = session.metadata&.dig("_milestones_seen") || []

        MILESTONES.select { |m| progress >= m && !seen.include?(m) }
      end

      def mark_seen!(session, milestones)
        seen = session.metadata&.dig("_milestones_seen") || []
        new_seen = (seen + milestones).uniq.sort
        meta = (session.metadata || {}).merge("_milestones_seen" => new_seen)
        session.update!(metadata: meta)
      end
    end
  end
end
