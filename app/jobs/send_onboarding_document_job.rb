# frozen_string_literal: true

class SendOnboardingDocumentJob < ApplicationJob
  queue_as :default

  def perform delivery_id
    delivery = DocumentDelivery.find delivery_id
    OnboardingMailer.document_packet(delivery).deliver_now
    delivery.update! status: "sent", sent_at: Time.current
  rescue StandardError => error
    delivery&.update status: "failed", error_message: error.message
    raise
  end
end
