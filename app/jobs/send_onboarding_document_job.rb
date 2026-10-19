# frozen_string_literal: true

class SendOnboardingDocumentJob < ApplicationJob
  queue_as :default

  def perform delivery_id
    delivery = DocumentDelivery.find delivery_id
    if delivery.onboarding_document.docusign?
      Docusign::SendEnvelope.call delivery
    else
      OnboardingMailer.document_packet(delivery).deliver_now
      delivery.update! status: "sent", sent_at: Time.current
    end
  rescue StandardError => error
    delivery&.update status: "failed", error_message: error.message
    Docusign::SendEnvelope.fail_attached delivery, error if delivery
    raise
  end
end
