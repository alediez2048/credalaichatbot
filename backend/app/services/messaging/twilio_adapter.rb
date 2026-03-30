# frozen_string_literal: true

require "base64"
require "net/http"
require "openssl"
require "uri"

module Messaging
  class TwilioAdapter < Provider
    PROVIDER = "twilio"

    def initialize(account_sid: ENV["TWILIO_ACCOUNT_SID"], auth_token: ENV["TWILIO_AUTH_TOKEN"], from_number: ENV["TWILIO_PHONE_NUMBER"])
      @account_sid = account_sid
      @auth_token = auth_token
      @from_number = from_number
    end

    def send_message(to:, text:)
      return { success: false, provider: PROVIDER, error: "Twilio credentials missing" } if missing_credentials?

      uri = URI("https://api.twilio.com/2010-04-01/Accounts/#{@account_sid}/Messages.json")
      req = Net::HTTP::Post.new(uri)
      req.basic_auth(@account_sid, @auth_token)
      req.set_form_data("From" => @from_number, "To" => Messaging::PhoneNumber.normalize(to), "Body" => text.to_s)

      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
      parsed = JSON.parse(res.body) rescue {}

      if res.code.to_i.between?(200, 299)
        { success: true, provider: PROVIDER, external_id: parsed["sid"], raw: parsed }
      else
        { success: false, provider: PROVIDER, error: parsed["message"] || "Twilio send failed", raw: parsed }
      end
    end

    def parse_inbound(params)
      {
        provider: PROVIDER,
        from: Messaging::PhoneNumber.normalize(params["From"] || params[:From]),
        body: (params["Body"] || params[:Body]).to_s,
        external_id: params["MessageSid"] || params[:MessageSid]
      }
    end

    # Twilio signature verification for form-encoded webhook requests.
    def verify_signature(url:, params:, signature:)
      return true if @auth_token.blank?
      return false if signature.blank?

      expected = compute_signature(url: url, params: params)
      ActiveSupport::SecurityUtils.secure_compare(expected, signature.to_s)
    end

    private

    def missing_credentials?
      @account_sid.blank? || @auth_token.blank? || @from_number.blank?
    end

    def compute_signature(url:, params:)
      data = String.new(url.to_s)
      params.to_h.sort_by { |k, _v| k.to_s }.each do |k, v|
        data << k.to_s << v.to_s
      end
      digest = OpenSSL::HMAC.digest("sha1", @auth_token, data)
      Base64.strict_encode64(digest)
    end
  end
end
