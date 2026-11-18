# frozen_string_literal: true

class CreateRecruitingGoals < ActiveRecord::Migration[8.0]
  def change
    create_table :recruiting_goals do |t|
      t.decimal :revenue_goal, precision: 14, scale: 2, null: false, default: 15_000_000
      t.date :season_start, null: false
      t.date :season_end, null: false
      t.timestamps
    end

    create_table :recruiting_goal_weeks do |t|
      t.references :recruiting_goal, null: false, foreign_key: true
      t.integer :week_number, null: false
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.decimal :projected_revenue, precision: 14, scale: 2
      t.decimal :expenses, precision: 14, scale: 2
      t.decimal :percent_to_goal_override, precision: 6, scale: 1
      t.decimal :percent_into_season_override, precision: 6, scale: 1
      t.timestamps
      t.index [:recruiting_goal_id, :week_number], unique: true, name: "index_recruiting_goal_weeks_on_goal_and_week"
    end
  end
end
