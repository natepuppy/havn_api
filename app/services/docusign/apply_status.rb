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

    def self.call payload
      new(payload).call
    end

    def initialize payload
      self.payload = payload.deep_stringify_keys
    end

    def call
      return if envelope_id.blank?

      deliveries = DocumentDelivery.where(docusign_envelope_id: envelope_id).includes(:onboarding_document, :rep).to_a
      return if deliveries.empty?

      if recipient_event?
        mark_rep_signed deliveries
      elsif (status = EVENTS[payload["event"].to_s])
        advance deliveries, status
      end
    end

    private

    attr_accessor :payload

    def envelope_id
      payload.dig("data", "envelopeId")
    end

    def recipient_event?
      payload["event"].to_s.in?(%w[recipient-completed recipient-signed])
    end

    def mark_rep_signed deliveries
      return unless rep_signed?(deliveries)

      agreements = deliveries.select { |delivery| delivery.onboarding_document&.rep_agreement? }
      advance agreements, "awaiting_corporate_signature"
    end

    def rep_signed? deliveries
      signers = Array(payload.dig("data", "envelopeSummary", "recipients", "signers"))
      recipient_id = payload.dig("data", "recipientId").to_s
      signer = signers.find { |row| row["recipientId"].to_s == recipient_id } if recipient_id.present?

      return rep_signer?(signer, deliveries) if signer
      return false if signers.any?

      recipient_id == "1"
    end

    def rep_signer? signer, deliveries
      role = signer["roleName"].to_s
      return true if role.casecmp("rep").zero?
      return false if role.casecmp("company").zero?

      email = signer["email"].to_s.strip.downcase
      email.present? && deliveries.any? { |delivery| delivery.rep.email.to_s.downcase == email }
    end

    def advance deliveries, status
      deliveries.each do |delivery|
        current = DocumentDelivery::STATUS_RANK.fetch(delivery.status, 0)
        incoming = DocumentDelivery::STATUS_RANK.fetch(status, 0)
        next if current >= incoming

        delivery.update! status: status, error_message: nil
      end
    end
  end
end
