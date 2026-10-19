# frozen_string_literal: true

module Docusign
  class WebhooksController < ApplicationController
    def create
      body = request.raw_post
      return head :unauthorized unless valid_signature?(body)

      ApplyStatus.call JSON.parse(body)
      head :ok
    rescue JSON::ParserError
      head :bad_request
    end

    private

    def valid_signature? body
      secret = Config.connect_key
      signature = request.headers["X-DocuSign-Signature-1"].to_s
      return false if secret.blank? || signature.blank?

      expected = Base64.strict_encode64 OpenSSL::HMAC.digest("SHA256", secret, body)
      ActiveSupport::SecurityUtils.secure_compare signature, expected
    end
  end
end
