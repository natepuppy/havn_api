# frozen_string_literal: true

class RecruitingGoal < ApplicationRecord
  has_many :weeks, class_name: "RecruitingGoalWeek", dependent: :destroy

  validates :revenue_goal, numericality: { greater_than: 0 }
  validates :season_start, :season_end, presence: true

  def self.current
    goal = first || create!(
      revenue_goal: 15_000_000,
      season_start: RecruitingGoals::Calendar::START,
      season_end: RecruitingGoals::Calendar::END_ON,
    )
    goal.sync_weeks!
    goal
  end

  def sync_weeks!
    RecruitingGoals::Calendar.weeks.each do |week|
      record = weeks.find_or_initialize_by(week_number: week[:week_number])
      record.starts_on = week[:starts_on]
      record.ends_on = week[:ends_on]
      record.save! if record.new_record? || record.changed?
    end
  end
end
