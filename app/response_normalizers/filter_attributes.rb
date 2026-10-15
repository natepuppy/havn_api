# frozen_string_literal: true

class FilterAttributes
  BASE_NORMALIZER = "BaseResponseNormalizer"

  def self.call attributes, hashified_attrs, normalizer_name
    new.call attributes, hashified_attrs, normalizer_name
  end

  def call attributes, hashified_attrs, normalizer_name
    return hashified_attrs if normalizer_name == BASE_NORMALIZER

    hashified_attrs.slice(*attributes)
  end
end
