# frozen_string_literal: true

class OnboardingDocumentNormalizer < ::BaseResponseNormalizer
  attributes(
    :id,
    :name,
    :description,
    :body,
    :active,
    :send_by_default,
    :required,
    :position,
    :created_at,
    :updated_at,
  )
end
