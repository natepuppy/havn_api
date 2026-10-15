# frozen_string_literal: true

module Reps
  class SendDocuments
    def self.call reps:, document_ids:
      return if reps.blank?

      new(reps, document_ids).call
    end

    def initialize reps, document_ids
      self.reps         = Array reps
      self.document_ids = Array(document_ids).map(&:to_i).uniq
    end

    def call
      documents = OnboardingDocument.active.where(id: document_ids).order(:position, :id)

      reps.each do |rep|
        documents.each do |document|
          delivery = DocumentDelivery.create!(
            rep:                   rep,
            onboarding_document:   document,
            recipient_email:       rep.email,
            status:                "queued",
          )
          SendOnboardingDocumentJob.perform_later delivery.id
        end

        rep.update! status: "docs_sent" if documents.any?
      end

      reps
    end

    private

    attr_accessor :reps, :document_ids
  end
end
