# frozen_string_literal: true

module OnboardingDocuments
  class Build
    PERMITTED_ATTRIBUTES = [
      :name,
      :description,
      :body,
      :active,
      :send_by_default,
      :required,
      :position,
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
      params.map { |param| ::OnboardingDocument.new param.to_h }
    end

    private

    attr_accessor :params
  end
end
