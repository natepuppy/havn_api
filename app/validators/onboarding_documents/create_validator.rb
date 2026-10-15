# frozen_string_literal: true

module OnboardingDocuments
  class CreateValidator < BaseValidator
    params do
      required(:onboarding_documents).maybe(:array, min_size?: 1).each do
        hash do
          required(:name).filled :string
          optional(:description).maybe :string
          required(:body).filled :string
          optional(:active).value :bool
          optional(:send_by_default).value :bool
          optional(:required).value :bool
          optional(:position).filled :integer
        end
      end
    end
  end
end
