# frozen_string_literal: true

class AllowSharedDocusignEnvelope < ActiveRecord::Migration[8.0]
  def change
    remove_index :document_deliveries, :docusign_envelope_id, unique: true
    add_index :document_deliveries, :docusign_envelope_id
  end
end
