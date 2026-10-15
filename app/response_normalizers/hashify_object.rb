# frozen_string_literal: true

class HashifyObject
  def self.call object
    new.call object
  end

  def call object
    hashify(object).with_indifferent_access
  end

  private

  def hashify object
    return object if object.is_a? Hash
    return object.attributes if object.respond_to? :attributes

    object.to_h
  end
end
