# frozen_string_literal: true

class DocumentDelivery < ApplicationRecord
  STATUSES = %w[queued sent delivered awaiting_corporate_signature completed declined voided failed].freeze
  OUTBOUND_STATUSES = %w[sent delivered awaiting_corporate_signature completed].freeze
  STATUS_RANK = {
    "queued" => 0,
    "failed" => 0,
    "sent" => 1,
    "delivered" => 2,
    "awaiting_corporate_signature" => 3,
    "completed" => 4,
    "declined" => 4,
    "voided" => 4,
  }.freeze

  belongs_to :rep
  belongs_to :onboarding_document, -> { with_deleted }

  validates :recipient_email, :status, presence: true
  validates :status, inclusion: { in: STATUSES }
end
