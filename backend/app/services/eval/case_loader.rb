# frozen_string_literal: true

module Eval
  class CaseLoader
    CASES_DIR = Rails.root.join("test/eval/cases")

    def self.load_all
      Dir.glob(CASES_DIR.join("*.yml")).flat_map do |file|
        YAML.load_file(file) || []
      end
    end

    def self.load_category(category)
      load_all.select { |c| c["category"] == category }
    end
  end
end
