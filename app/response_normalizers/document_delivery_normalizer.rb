# frozen_string_literal: true

class DocumentDeliveryNormalizer < ::BaseResponseNormalizer
  attributes(
    :id,
    :rep_id,
    :onboarding_document_id,
    :recipient_email,
    :status,
    :sent_at,
    :error_message,
    :created_at,
  )

  custom_attributes :document_name

  def document_name object
    object.onboarding_document&.name
  end
end
