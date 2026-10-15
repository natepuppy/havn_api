# frozen_string_literal: true

module Reps
  class UpdateValidator < BaseValidator
    params do
      required(:reps).maybe(:array, min_size?: 1).each do
        hash do
          required(:id).filled :integer
          optional(:active).value :bool
          optional(:onboarding_completed).value :bool
        end
      end
    end
  end
end
