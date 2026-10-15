# frozen_string_literal: true

class AddSendByDefaultToOnboardingDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :onboarding_documents, :send_by_default, :boolean, null: false, default: true
  end
end
