# frozen_string_literal: true

class DocumentDelivery < ApplicationRecord
  STATUSES = %w[queued sent failed].freeze

  belongs_to :rep
  belongs_to :onboarding_document, -> { with_deleted }

  validates :recipient_email, :status, presence: true
  validates :status, inclusion: { in: STATUSES }
end
