# frozen_string_literal: true

module Reps
  class Save
    def self.call reps:, columns_to_update: nil
      return if reps.blank?

      new(reps, columns_to_update).call
    end

    def initialize reps, columns_to_update
      self.reps             = reps
      self.columns_to_update = columns_to_update
    end

    def call
      options = {}
      options[:on_duplicate_key_update] = columns_to_update if columns_to_update.present?
      result = Rep.import reps, **options
      imported = Rep.includes(:recruited_by, document_deliveries: :onboarding_document).where(id: result.ids).index_by(&:id)
      result.ids.map { |id| imported[id] }
    end

    private

    attr_accessor :reps, :columns_to_update
  end
end
