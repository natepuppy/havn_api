# frozen_string_literal: true

module Permissions
  class CreateValidator < BaseValidator
    params do
      required(:permissions).maybe(:array, min_size?: 1).each do
        hash do
          optional(:role_id).maybe :integer
          optional(:user_id).maybe :integer
          required(:action).filled :string
          required(:allowed).value :bool
          optional(:description).maybe :string
        end
      end
    end

    rule(:permissions).each do
      key(%i[permissions action]).failure("is not a known permission") unless Permission::ACTIONS.key? value[:action]
      scoped = value[:role_id].present? ^ value[:user_id].present?
      key(%i[permissions role_id]).failure("choose a role or a user") unless scoped
    end
  end
end
