# frozen_string_literal: true

module Reps
  class Build
    PERMITTED_ATTRIBUTES = [
      :first_name,
      :last_name,
      :email,
      :phone,
      :street,
      :city,
      :state,
      :zip,
      :start_date,
      :end_date,
      :shirt_size,
      :drivers_license_number,
      :market,
      :level,
      :notes,
      :recruited_by_id,
      :status,
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
      reps = params.map do |param|
        attributes = param.to_h
        attributes["status"] = "pending" if attributes["status"].blank? && attributes[:status].blank?
        ::Rep.new attributes
      end

      Current.set_previous_and_current_entities(
        previous_entities: [],
        current_entities:  reps,
      )

      reps
    end

    private

    attr_accessor :params
  end
end
