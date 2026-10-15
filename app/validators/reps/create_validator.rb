# frozen_string_literal: true

# {
#   "reps": [
#     {
#       "first_name": "Avery",
#       "last_name": "Cole",
#       "email": "avery@example.com",
#       "phone": "(801) 555-0100",
#       "street": "100 Main St",
#       "city": "Salt Lake City",
#       "state": "UT",
#       "zip": "84101",
#       "start_date": "2026-10-15",
#       "market": "Wasatch Front",
#       "level": "Rookie",
#       "housing": "Single housing",
#       "recruited_by_id": 2,
#       "notes": "Comes from a lawn route",
#       "document_ids": [1, 2]
#     }
#   ]
# }

module Reps
  class CreateValidator < BaseValidator
    params do
      required(:reps).maybe(:array, min_size?: 1).each do
        hash do
          required(:first_name).filled :string
          required(:last_name).filled :string
          required(:email).filled :string
          required(:phone).filled :string
          optional(:street).maybe :string
          optional(:city).maybe :string
          optional(:state).maybe :string
          optional(:zip).maybe :string
          required(:start_date).filled :string
          optional(:end_date).maybe :string
          required(:shirt_size).filled :string
          required(:drivers_license_number).filled :string
          optional(:market).maybe :string
          required(:level).filled :string
          required(:housing).filled :string
          required(:recruited_by_id).filled :integer
          optional(:notes).maybe :string
          required(:document_ids).filled(:array, min_size?: 1).each(:integer)
        end
      end
    end

    rule(:reps).each do
      key(%i[reps email]).failure :email_format unless ValidEmail2::Address.new(value[:email].to_s).valid?
      key(%i[reps phone]).failure :phone_number_format if value[:phone].present? && value[:phone].match?(PHONE_REG_EXP) == false
      key(%i[reps zip]).failure :zip_code_format if value[:zip].present? && value[:zip].match?(ZIPCODE_REGEX) == false

      start_date = nil
      begin
        start_date = Date.iso8601 value[:start_date].to_s
      rescue Date::Error
        key(%i[reps start_date]).failure :datetime_format
      end

      if value[:end_date].present?
        begin
          end_date = Date.iso8601 value[:end_date].to_s
          key(%i[reps end_date]).failure("must be on or after the start date") if start_date && end_date < start_date
        rescue Date::Error
          key(%i[reps end_date]).failure :datetime_format
        end
      end

      key(%i[reps shirt_size]).failure("is not a shirt size") unless Rep::SHIRT_SIZES.include? value[:shirt_size]
      key(%i[reps level]).failure :level_must_be_known unless User::LEVELS.include? value[:level]
      key(%i[reps housing]).failure :housing_must_be_known unless User::HOUSINGS.include? value[:housing]

      if value[:market].present? && !Market.exists?(name: value[:market])
        key(%i[reps market]).failure :market_must_exist
      end

      recruiter = User.recruiters.find_by id: value[:recruited_by_id]
      key(%i[reps recruited_by_id]).failure :recruiter_must_exist if recruiter.nil?

      ids = Array(value[:document_ids]).map(&:to_i)
      found = OnboardingDocument.active.where(id: ids).count
      key(%i[reps document_ids]).failure :documents_must_exist if found != ids.uniq.size

      required_ids = OnboardingDocument.active.where(required: true).pluck(:id)
      key(%i[reps document_ids]).failure :required_documents if (required_ids - ids).any?
    end
  end
end
