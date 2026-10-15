# frozen_string_literal: true

module ManagedUsers
  class CreateValidator < BaseValidator
    params do
      required(:users).maybe(:array, min_size?: 1).each do
        hash do
          required(:first_name).filled :string
          required(:last_name).filled :string
          required(:email).filled :string
          optional(:phone).maybe :string
          required(:role).filled :string
          required(:password).filled :string
          required(:password_confirmation).filled :string
          optional(:team_ids).array(:integer)
        end
      end
    end

    rule(:users).each do
      key(%i[users email]).failure :email_format unless ValidEmail2::Address.new(value[:email].to_s).valid?
      key(%i[users role]).failure("is not a known role") unless Role.exists?(code: value[:role])
      if value[:password].present? && value[:password] != value[:password_confirmation]
        key(%i[users password_confirmation]).failure("does not match the password")
      end
    end
  end
end
