# frozen_string_literal: true

module Permissions
  class Update
    PERMITTED_ATTRIBUTES = (Build::PERMITTED_ATTRIBUTES + [:id]).freeze

    def self.call params
      return if params.blank?

      cleaned = ServiceHelpers::CleanBuildParams.call(
        params:               params,
        permitted_attributes: PERMITTED_ATTRIBUTES,
      )

      cleaned.map do |param|
        attributes = param.to_h
        permission = ::Permission.find attributes["id"] || attributes[:id]
        permission.assign_attributes attributes.except("id", :id)
        permission
      end
    end
  end
end
