# frozen_string_literal: true

class RenameTerritoryToMarketAndAddLevels < ActiveRecord::Migration[8.0]
  def up
    rename_column :reps, :territory, :market
    add_column :users, :level, :string
    add_column :users, :housing, :string

    create_table :markets do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :markets, :name, unique: true

    execute <<~SQL.squish
      INSERT INTO markets (name, created_at, updated_at)
      SELECT DISTINCT market, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM reps
      WHERE market IS NOT NULL AND market <> ''
    SQL
  end

  def down
    drop_table :markets
    remove_column :users, :housing
    remove_column :users, :level
    rename_column :reps, :market, :territory
  end
end
