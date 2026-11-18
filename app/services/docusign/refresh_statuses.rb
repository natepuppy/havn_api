# frozen_string_literal: true

module Docusign
  # DocuSign Connect cannot reach local development, so a signed envelope stays
  # "sent" until something asks DocuSign. Pull the current status for any
  # delivery that can still move forward.
  class RefreshStatuses
    OPEN = %w[queued sent delivered awaiting_corporate_signature].freeze

    def self.call deliveries:
      new(deliveries).call
    end

    def initialize deliveries
      self.deliveries = Array(deliveries)
    end

    def call
      return unless Config.configured?

      pending = deliveries.select { |delivery| refreshable? delivery }
      return if pending.empty?

      by_id = client.envelope_statuses(pending.map(&:docusign_envelope_id).uniq).index_by { |row| row["envelopeId"] }
      pending.group_by(&:docusign_envelope_id).each_key do |envelope_id|
        apply_envelope envelope_id, by_id[envelope_id]
      end
    rescue Client::Error => error
      Rails.logger.warn "DocuSign status refresh failed: #{error.message}"
    end

    private

    attr_accessor :deliveries

    def refreshable? delivery
      delivery.docusign_envelope_id.present? && OPEN.include?(delivery.status)
    end

    def apply_envelope envelope_id, row
      return if row.blank?

      case row["status"].to_s
      when "completed", "signed"
        ApplyStatus.call("event" => "envelope-completed", "data" => { "envelopeId" => envelope_id })
      when "declined"
        ApplyStatus.call("event" => "envelope-declined", "data" => { "envelopeId" => envelope_id })
      when "voided"
        ApplyStatus.call("event" => "envelope-voided", "data" => { "envelopeId" => envelope_id })
      when "sent", "delivered"
        apply_open envelope_id, row["status"].to_s
      end
    end

    def apply_open envelope_id, status
      signers = Array(client.envelope_recipients(envelope_id)["signers"])
      rep = signers.find { |signer| signer["roleName"].to_s.casecmp("rep").zero? && signer["status"].to_s == "completed" }
      rep ||= signers.find { |signer| signer["recipientId"].to_s == "1" && signer["status"].to_s == "completed" && signer["roleName"].to_s.casecmp("company") != 0 }
      if rep
        ApplyStatus.call(
          "event" => "recipient-completed",
          "data" => {
            "envelopeId" => envelope_id,
            "recipientId" => rep["recipientId"],
            "envelopeSummary" => { "recipients" => { "signers" => signers } },
          },
        )
        return
      end

      return unless status == "delivered"

      ApplyStatus.call("event" => "envelope-delivered", "data" => { "envelopeId" => envelope_id })
    end

    def client
      @client ||= Client.new
    end
  end
end
