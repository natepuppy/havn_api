# frozen_string_literal: true

module Permissions
  class UpdateValidator < BaseValidator
    params do
      required(:permissions).maybe(:array, min_size?: 1).each do
        hash do
          required(:id).filled :integer
          optional(:role_id).maybe :integer
          optional(:user_id).maybe :integer
          optional(:action).filled :string
          optional(:allowed).value :bool
          optional(:description).maybe :string
        end
      end
    end
  end
end
