# frozen_string_literal: true

class NormalizeCustomAttributes
  def self.call object, custom_attributes, normalizer
    custom_attributes.index_with do |attr|
      normalizer.public_send attr, object
    end
  end
end
