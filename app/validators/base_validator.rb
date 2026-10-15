# frozen_string_literal: true

class BaseValidator < Dry::Validation::Contract
  config.messages.backend       = :i18n
  config.messages.top_namespace = "param_validation"
  config.messages.load_paths << "config/locales/param_validation.en.yml"

  PHONE_REG_EXP = /^\(\d{3}\)\s\d{3}-\d{4}/
  ZIPCODE_REGEX = /\A\d{5}\z/

  register_macro :string_cannot_be_blank do
    key.failure :string_cannot_be_blank if key? && value.blank?
  end

  register_macro :email_format do
    key.failure :email_format if key? && value.present? && !ValidEmail2::Address.new(value).valid?
  end

  register_macro :phone_number_format do
    if key? && value.present? && value.match?(PHONE_REG_EXP) == false
      key.failure :phone_number_format
    end
  end

  register_macro :zip_code_format do
    key.failure :zip_code_format if key? && value.present? && value.match?(ZIPCODE_REGEX) == false
  end

  register_macro :date_format do
    if key? && value.present?
      begin
        Date.iso8601 value.to_s
      rescue Date::Error
        key.failure :datetime_format
      end
    end
  end

  def self.call params
    params = params.to_unsafe_h if params.is_a? ::ActionController::Parameters
    new.call params
  end
end
