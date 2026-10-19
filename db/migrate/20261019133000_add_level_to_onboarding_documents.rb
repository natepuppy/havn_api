# frozen_string_literal: true

class AddLevelToOnboardingDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :onboarding_documents, :level, :string
    add_column :onboarding_documents, :docusign_template_id, :string
  end
end
