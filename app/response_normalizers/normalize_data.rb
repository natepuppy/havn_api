# frozen_string_literal: true

class NormalizeData
  def self.call attributes, custom_attributes, object, normalizer
    new.call attributes, custom_attributes, object, normalizer
  end

  def call attributes, custom_attributes, object, normalizer
    normalizer_name = normalizer.class.name

    HashifyObject.call(object)
                 .then { |hashified_attrs|
                   FilterAttributes.call attributes, hashified_attrs, normalizer_name
                 }
                 .then { |filtered_attrs| NormalizeAttributes.call filtered_attrs }
                 .merge NormalizeCustomAttributes.call(object, custom_attributes, normalizer)
  end
end
