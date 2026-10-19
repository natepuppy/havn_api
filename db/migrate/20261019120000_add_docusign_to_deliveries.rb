# frozen_string_literal: true

class AddDocusignToDeliveries < ActiveRecord::Migration[8.0]
  def change
    add_column :document_deliveries, :docusign_envelope_id, :string
    add_index :document_deliveries, :docusign_envelope_id, unique: true
  end
end
