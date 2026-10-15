# frozen_string_literal: true

module ServiceHelpers
  module CleanBuildParams
    def self.call params:, permitted_attributes:
      Array.wrap(params).map do |param|
        if param.is_a? ActionController::Parameters
          ActionController::Parameters.new(param.to_unsafe_h.slice(*permitted_attributes.map(&:to_s), *permitted_attributes)).permit!
        else
          param.slice(*permitted_attributes.map(&:to_s), *permitted_attributes)
        end
      end
    end
  end
end
