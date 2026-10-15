# frozen_string_literal: true

module OnboardingDocuments
  class Save
    def self.call documents:, columns_to_update: nil
      return if documents.blank?

      options = {}
      options[:on_duplicate_key_update] = columns_to_update if columns_to_update.present?
      result = OnboardingDocument.import documents, **options
      OnboardingDocument.where(id: result.ids).order(:position, :id)
    end
  end
end
