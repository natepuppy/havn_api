# frozen_string_literal: true

module ManagedUsers
  class UpdateValidator < BaseValidator
    params do
      required(:users).maybe(:array, min_size?: 1).each do
        hash do
          required(:id).filled :integer
          optional(:role).filled :string
          optional(:deleted_at).maybe :string
          optional(:team_ids).array(:integer)
        end
      end
    end

    rule(:users).each do
      if value[:role].present? && !Role.exists?(code: value[:role])
        key(%i[users role]).failure("is not a known role")
      end
    end
  end
end
