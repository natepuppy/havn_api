# frozen_string_literal: true

module Markets
  class CreateValidator < BaseValidator
    params do
      required(:markets).maybe(:array, min_size?: 1).each do
        hash do
          required(:name).filled :string
        end
      end
    end

    rule(:markets).each do
      name = value[:name].to_s.strip
      key(%i[markets name]).failure :market_name_taken if name.present? && Market.exists?(name: name)
    end
  end
end
