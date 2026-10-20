# frozen_string_literal: true

module Docusign
  # DocuSign Connect cannot reach local development, so a signed envelope stays
  # "sent" until something asks DocuSign. Pull the current status for any
  # delivery that can still move forward.
  class RefreshStatuses
    OPEN = %w[queued sent delivered].freeze
    STATUSES = {
      "sent" => "sent",
      "delivered" => "delivered",
      "signed" => "completed",
      "completed" => "completed",
      "declined" => "declined",
      "voided" => "voided",
    }.freeze

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
      pending.each { |delivery| apply delivery, by_id[delivery.docusign_envelope_id] }
    rescue Client::Error => error
      Rails.logger.warn "DocuSign status refresh failed: #{error.message}"
    end

    private

    attr_accessor :deliveries

    def refreshable? delivery
      delivery.docusign_envelope_id.present? && OPEN.include?(delivery.status)
    end

    def apply delivery, row
      return if row.blank?

      status = STATUSES[row["status"].to_s]
      return if status.blank?
      return if ApplyStatus::RANK.fetch(delivery.status, 0) >= ApplyStatus::RANK.fetch(status, 0)

      delivery.update! status: status, error_message: nil
    end

    def client
      @client ||= Client.new
    end
  end
end
