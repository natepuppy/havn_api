# frozen_string_literal: true

class AddRevenueProjections < ActiveRecord::Migration[8.0]
  def change
    add_column :reps, :last_year_revenue, :decimal, precision: 12, scale: 2
    add_column :reps, :projected_revenue, :decimal, precision: 12, scale: 2

    create_table :level_finish_rates do |t|
      t.string :level, null: false
      t.decimal :finish_rate, precision: 5, scale: 2, null: false, default: 0
      t.timestamps
      t.index :level, unique: true
    end
  end
end
