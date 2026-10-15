# frozen_string_literal: true

class NormalizeAttributes
  def self.call normalized_attributes
    new.call normalized_attributes
  end

  def call normalized_attributes
    normalized_attributes.map { |name, value|
      value = value.to_i if name.ends_with?("_at") && value.is_a?(ActiveSupport::TimeWithZone)

      [name, value]
    }.to_h
  end
end
