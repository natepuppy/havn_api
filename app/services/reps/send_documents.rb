# frozen_string_literal: true

module Reps
  class SendDocuments
    # actor: the user sending the documents. Admins get their explicit addendum
    # selection honored; everyone else gets the addendum that matches the rep's level.
    def self.call reps:, document_ids:, actor: nil
      return if reps.blank?

      new(reps, document_ids, actor).call
    end

    def initialize reps, document_ids, actor
      self.reps         = Array reps
      self.document_ids = Array(document_ids).map(&:to_i).uniq
      self.actor        = actor
    end

    def call
      self.documents = OnboardingDocument.active.where(id: document_ids).order(:position, :id).to_a

      reps.each do |rep|
        selected = documents_for rep
        deliveries = selected.map do |document|
          DocumentDelivery.create!(
            rep:                   rep,
            onboarding_document:   document,
            recipient_email:       rep.email,
            status:                "queued",
          )
        end
        deliveries.each do |delivery|
          next if attached_addendum?(delivery, selected)

          SendOnboardingDocumentJob.perform_later delivery.id
        end

        rep.update! status: "docs_sent" if selected.any?
      end

      reps
    end

    private

    attr_accessor :reps, :document_ids, :documents, :actor

    def attached_addendum? delivery, selected
      return false if delivery.onboarding_document.level.blank?

      selected.any? { |document| document.level.blank? && document.agreement? && document.docusign? }
    end

    def documents_for rep
      agreement = OnboardingDocument.active.where(level: nil).where("name ILIKE ?", "%agreement%")
      chosen = admin_override? ? documents : level_documents_for(rep)
      (chosen + agreement).uniq.sort_by { |document| [document.position, document.id] }
    end

    def level_documents_for rep
      level = rep.level
      match = OnboardingDocument.active.find_by level: level
      documents.select { |document| document.for_level? level } + [match].compact
    end

    def admin_override?
      actor.respond_to?(:admin?) && actor.admin?
    end
  end
end
