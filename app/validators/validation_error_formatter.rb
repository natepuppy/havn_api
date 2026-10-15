# frozen_string_literal: true

class ValidationErrorFormatter
  def self.call validator
    new.call validator
  end

  def call validator
    return [] if validator.success?

    errors = validator.errors(full: true).to_h.values.flatten
    flatten_error errors
  end

  private

  def flatten_error errors
    formatted_errors = []

    errors.each do |error|
      formatted_errors << error if error.is_a? String
      formatted_errors << flatten_error(error.values.flatten) if error.is_a? Hash
    end
    formatted_errors.flatten
  end
end
