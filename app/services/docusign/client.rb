# frozen_string_literal: true

require "json"
require "net/http"
require "jwt"

module Docusign
  class Client
    class Error < StandardError; end

    def create_envelope payload
      response = request(
        Net::HTTP::Post,
        "/restapi/v2.1/accounts/#{Config.account_id}/envelopes",
        payload,
      )
      JSON.parse response.body
    end

    def envelope_statuses ids
      ids.each_slice(50).flat_map do |slice|
        query = URI.encode_www_form(
          envelope_ids: slice.join(","),
          from_date: "2020-01-01T00:00:00Z",
          status: "any",
        )
        response = request(
          Net::HTTP::Get,
          "/restapi/v2.1/accounts/#{Config.account_id}/envelopes?#{query}",
        )
        JSON.parse(response.body).fetch("envelopes", [])
      end
    end

    private

    def request klass, path, payload = nil
      uri = URI.join("#{Config.rest_host}/", path.sub(%r{\A/}, ""))
      http = Net::HTTP.new uri.host, uri.port
      http.use_ssl = true
      message = klass.new uri
      message["Authorization"] = "Bearer #{access_token}"
      message["Content-Type"] = "application/json"
      message.body = JSON.generate(payload) if payload
      response = http.request message
      return response if response.is_a? Net::HTTPSuccess

      raise Error, "DocuSign #{response.code}: #{response.body}"
    end

    def access_token
      uri = URI("#{Config.oauth_host}/oauth/token")
      http = Net::HTTP.new uri.host, uri.port
      http.use_ssl = true
      message = Net::HTTP::Post.new uri
      message["Content-Type"] = "application/x-www-form-urlencoded"
      message.body = URI.encode_www_form(
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: assertion,
      )
      response = http.request message
      body = JSON.parse response.body
      return body.fetch("access_token") if response.is_a? Net::HTTPSuccess

      raise Error, "DocuSign auth #{response.code}: #{response.body}"
    end

    def assertion
      now = Time.now.to_i
      JWT.encode(
        {
          iss: Config.integration_key,
          sub: Config.user_id,
          aud: URI(Config.oauth_host).host,
          iat: now,
          exp: now + 3600,
          scope: "signature impersonation",
        },
        Config.private_key,
        "RS256",
      )
    end
  end
end
