# frozen_string_literal: true

require "test_helper"

module Documents
  class TypeRegistryTest < ActiveSupport::TestCase
    test "loads all document types from YAML" do
      types = Documents::TypeRegistry.all
      assert types.size >= 4
      assert types.key?("drivers_license")
      assert types.key?("w4")
      assert types.key?("passport")
      assert types.key?("i9")
    end

    test "lookup returns type definition" do
      defn = Documents::TypeRegistry.find("drivers_license")
      assert_equal "Driver's License", defn["display_name"]
      assert defn["fields"].is_a?(Array)
      assert defn["fields"].any? { |f| f["name"] == "full_name" }
    end

    test "lookup raises for unknown type" do
      assert_raises(Documents::TypeRegistry::UnknownTypeError) do
        Documents::TypeRegistry.find("unknown_document")
      end
    end

    test "fields_for returns field names for a type" do
      fields = Documents::TypeRegistry.fields_for("w4")
      assert_includes fields, "full_name"
      assert_includes fields, "ssn_last4"
    end

    test "validation_rules_for returns rules hash" do
      rules = Documents::TypeRegistry.validation_rules_for("drivers_license")
      assert rules.is_a?(Hash)
      assert rules.key?("date_of_birth") || rules.key?("license_number")
    end

    test "all types have required keys" do
      Documents::TypeRegistry.all.each do |key, defn|
        assert defn["display_name"].present?, "#{key} missing display_name"
        assert defn["fields"].is_a?(Array), "#{key} fields must be an array"
      end
    end
  end
end
