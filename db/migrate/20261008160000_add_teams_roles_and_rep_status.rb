# frozen_string_literal: true

class AddTeamsRolesAndRepStatus < ActiveRecord::Migration[8.0]
  def change
    add_column :reps, :active, :boolean, null: false, default: true
    add_column :reps, :onboarding_completed, :boolean, null: false, default: false

    create_table :teams do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :teams, :name, unique: true

    create_table :manager_teams do |t|
      t.references :user, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.timestamps
    end
    add_index :manager_teams, [:user_id, :team_id], unique: true
  end
end
