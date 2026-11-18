# frozen_string_literal: true

class RecruitingGoalsController < ApplicationController
  def show
    require_admin!
    return if performed?

    render json: { data: payload, errors: [] }
  end

  def update
    require_admin!
    return if performed?

    goal = RecruitingGoal.current
    ActiveRecord::Base.transaction do
      goal.update! revenue_goal: params[:revenue_goal] if params[:revenue_goal].present?
      Array(params[:weeks]).each do |row|
        raw = row.respond_to?(:to_unsafe_h) ? row.to_unsafe_h : row.to_h
        raw = raw.with_indifferent_access
        week = goal.weeks.find_by!(week_number: raw[:week_number])
        week.update!(
          projected_revenue: blank_money(raw[:projected_revenue]),
          expenses: blank_money(raw[:expenses]),
          percent_to_goal_override: blank_percent(raw[:percent_to_goal_override]),
          percent_into_season_override: blank_percent(raw[:percent_into_season_override]),
        )
      end
    end
    render json: { data: payload, errors: [] }
  rescue ActiveRecord::RecordInvalid => error
    render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
  end

  private

  def require_admin!
    return if current_user&.admin?

    render json: { errors: ["Unauthorized: Insufficient permissions"] }, status: :forbidden
  end

  def blank_money value
    return nil if value.blank?

    value
  end

  def blank_percent value
    return nil if value.nil? || value == ""

    value
  end

  def payload
    goal = RecruitingGoal.current
    weeks = goal.weeks.order(:week_number).to_a
    {
      revenue_goal: goal.revenue_goal.to_f,
      season_start: goal.season_start,
      season_end: goal.season_end,
      total_weeks: RecruitingGoals::Calendar::WEEKS,
      current_projected_revenue: Rep.sum(:projected_revenue).to_f,
      weeks: weeks.map { |week| week_row(week) },
      totals: {
        previous_30_days: period_total(weeks, goal, Date.current - 30.days, Date.current),
        previous_12_months: period_total(weeks, goal, Date.current - 12.months, Date.current),
      },
    }
  end

  def week_row week
    {
      id: week.id,
      week_number: week.week_number,
      starts_on: week.starts_on,
      ends_on: week.ends_on,
      projected_revenue: week.projected_revenue&.to_f,
      expenses: week.expenses&.to_f,
      percent_to_goal: week.percent_to_goal&.to_f,
      percent_into_season: week.percent_into_season&.to_f,
      calculated_percent_to_goal: week.calculated_percent_to_goal&.to_f,
      calculated_percent_into_season: week.calculated_percent_into_season&.to_f,
      percent_to_goal_override: week.percent_to_goal_override&.to_f,
      percent_into_season_override: week.percent_into_season_override&.to_f,
    }
  end

  def period_total weeks, goal, start_on, end_on
    selected = weeks.select { |week| week.starts_on <= end_on && week.ends_on >= start_on }
    latest = selected.select { |week| week.projected_revenue.present? }.max_by(&:week_number)
    expenses = selected.sum { |week| week.expenses || 0 }
    {
      expenses: expenses.to_f,
      projected_revenue: latest&.projected_revenue&.to_f,
      percent_to_goal: latest&.percent_to_goal&.to_f,
    }
  end
end
