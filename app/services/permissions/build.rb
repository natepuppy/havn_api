# frozen_string_literal: true

module Permissions
  class Build
    PERMITTED_ATTRIBUTES = [
      :role_id,
      :user_id,
      :action,
      :allowed,
      :description,
    ].freeze

    def self.call params
      return if params.blank?

      new(params).call
    end

    def initialize params
      self.params = ServiceHelpers::CleanBuildParams.call(
        params:               params,
        permitted_attributes: PERMITTED_ATTRIBUTES,
      )
    end

    def call
      params.map { |param| ::Permission.new param.to_h }
    end

    private

    attr_accessor :params
  end
end
