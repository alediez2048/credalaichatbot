# frozen_string_literal: true

require "test_helper"

module Documents
  class UploadValidatorTest < ActiveSupport::TestCase
    test "accepts PNG file under 10 MB" do
      file = mock_upload("test.png", "image/png", 1.megabyte)
      result = Documents::UploadValidator.validate(file)
      assert result[:valid], result[:errors].inspect
    end

    test "accepts JPEG file" do
      file = mock_upload("photo.jpg", "image/jpeg", 2.megabytes)
      result = Documents::UploadValidator.validate(file)
      assert result[:valid]
    end

    test "accepts PDF file" do
      file = mock_upload("doc.pdf", "application/pdf", 5.megabytes)
      result = Documents::UploadValidator.validate(file)
      assert result[:valid]
    end

    test "rejects file over 10 MB" do
      file = mock_upload("big.png", "image/png", 11.megabytes)
      result = Documents::UploadValidator.validate(file)
      assert_not result[:valid]
      assert result[:errors].any? { |e| e.include?("too large") }
    end

    test "rejects unsupported MIME type" do
      file = mock_upload("virus.exe", "application/x-msdownload", 1.megabyte)
      result = Documents::UploadValidator.validate(file)
      assert_not result[:valid]
      assert result[:errors].any? { |e| e.include?("Unsupported") }
    end

    test "rejects nil file" do
      result = Documents::UploadValidator.validate(nil)
      assert_not result[:valid]
      assert result[:errors].any? { |e| e.include?("No file") }
    end

    test "rejects file with both invalid type and size" do
      file = mock_upload("big.zip", "application/zip", 15.megabytes)
      result = Documents::UploadValidator.validate(file)
      assert_not result[:valid]
      assert_equal 2, result[:errors].size
    end

    private

    def mock_upload(filename, content_type, size)
      file = OpenStruct.new(
        original_filename: filename,
        content_type: content_type,
        size: size
      )
      file
    end
  end
end
