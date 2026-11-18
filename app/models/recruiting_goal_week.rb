# frozen_string_literal: true

class RecruitingGoalWeek < ApplicationRecord
  belongs_to :recruiting_goal

  validates :week_number, :starts_on, :ends_on, presence: true
  validates :week_number, uniqueness: { scope: :recruiting_goal_id }
  validates :projected_revenue, :expenses,
            numericality: { greater_than_or_equal_to: 0 },
            allow_nil: true
  validates :percent_to_goal_override, :percent_into_season_override,
            numericality: { greater_than_or_equal_to: 0 },
            allow_nil: true

  def calculated_percent_to_goal
    goal = recruiting_goal.revenue_goal
    return nil if projected_revenue.nil? || goal.nil? || goal.zero?

    (projected_revenue / goal * 100).round(1)
  end

  def calculated_percent_into_season
    (week_number.to_d / RecruitingGoals::Calendar::WEEKS * 100).round(1)
  end

  def percent_to_goal
    percent_to_goal_override || calculated_percent_to_goal
  end

  def percent_into_season
    percent_into_season_override || calculated_percent_into_season
  end
end
