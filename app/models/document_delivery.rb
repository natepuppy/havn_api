# frozen_string_literal: true

class DocumentDelivery < ApplicationRecord
  STATUSES = %w[queued sent delivered completed declined voided failed].freeze
  OUTBOUND_STATUSES = %w[sent delivered completed].freeze

  belongs_to :rep
  belongs_to :onboarding_document, -> { with_deleted }

  validates :recipient_email, :status, presence: true
  validates :status, inclusion: { in: STATUSES }
end
