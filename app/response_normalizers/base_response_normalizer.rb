# frozen_string_literal: true

class BaseResponseNormalizer
  class << self
    attr_accessor :attrs, :custom_attrs

    def attributes *args
      self.attrs = args
    end

    def custom_attributes *args
      self.custom_attrs = args
    end
  end

  attr_accessor :errors

  def initialize object, params = {}
    self.object = object
    self.errors = params[:errors].presence || []
  end

  def to_json(*)
    to_h.to_json(*)
  end

  def to_h
    {
      data:      serialized_data,
      data_keys: {},
      errors:    errors,
    }.with_indifferent_access
  end

  def as_data
    to_h["data"]
  end

  private

  attr_accessor :object

  def serialized_data
    return {} if object.nil?
    return NormalizeData.call(attributes, custom_attributes, object, self) if single_object?

    object.map { |item| NormalizeData.call attributes, custom_attributes, item, self }
  end

  def attributes
    @attributes ||= self.class.attrs || []
  end

  def custom_attributes
    @custom_attributes ||= self.class.custom_attrs || []
  end

  def single_object?
    object.is_a?(Hash) || !object.is_a?(Enumerable)
  end
end
