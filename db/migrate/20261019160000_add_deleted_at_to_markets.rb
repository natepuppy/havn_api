# frozen_string_literal: true

class AddDeletedAtToMarkets < ActiveRecord::Migration[8.0]
  def change
    add_column :markets, :deleted_at, :datetime
    add_index :markets, :deleted_at

    remove_index :markets, :name
    add_index :markets, :name, unique: true, where: "deleted_at IS NULL"
  end
end
