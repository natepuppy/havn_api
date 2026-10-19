# frozen_string_literal: true

module Docusign
  class ApplyStatus
    EVENTS = {
      "envelope-sent" => "sent",
      "envelope-delivered" => "delivered",
      "envelope-completed" => "completed",
      "envelope-declined" => "declined",
      "envelope-voided" => "voided",
    }.freeze

    RANK = {
      "queued" => 0,
      "failed" => 0,
      "sent" => 1,
      "delivered" => 2,
      "completed" => 3,
      "declined" => 3,
      "voided" => 3,
    }.freeze

    def self.call payload
      new(payload).call
    end

    def initialize payload
      self.payload = payload.deep_stringify_keys
    end

    def call
      status = EVENTS[payload["event"].to_s]
      envelope_id = payload.dig("data", "envelopeId")
      return if status.blank? || envelope_id.blank?

      deliveries = DocumentDelivery.where(docusign_envelope_id: envelope_id)
      return if deliveries.none?

      deliveries.find_each do |delivery|
        next if RANK.fetch(delivery.status, 0) > RANK.fetch(status, 0)

        delivery.update! status: status, error_message: nil
      end
    end

    private

    attr_accessor :payload
  end
end
