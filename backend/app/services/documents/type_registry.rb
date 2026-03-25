# frozen_string_literal: true

module Documents
  class TypeRegistry
    CONFIG_PATH = Rails.root.join("config/document_types.yml")

    class UnknownTypeError < StandardError; end

    class << self
      def all
        @types ||= load_config
      end

      def find(type_key)
        defn = all[type_key.to_s]
        raise UnknownTypeError, "Unknown document type: #{type_key}" unless defn
        defn
      end

      def fields_for(type_key)
        find(type_key)["fields"].map { |f| f["name"] }
      end

      def validation_rules_for(type_key)
        fields = find(type_key)["fields"]
        fields.each_with_object({}) do |f, rules|
          rules[f["name"]] = f["format"] if f["format"].present?
        end
      end

      def extraction_hints_for(type_key)
        find(type_key)["extraction_hints"].to_s
      end

      def reload!
        @types = nil
      end

      private

      def load_config
        types = YAML.load_file(CONFIG_PATH)
        validate_config!(types)
        types
      end

      def validate_config!(types)
        types.each do |key, defn|
          raise "Document type '#{key}' missing display_name" unless defn["display_name"].present?
          raise "Document type '#{key}' fields must be an array" unless defn["fields"].is_a?(Array)
        end
      end
    end
  end
end
