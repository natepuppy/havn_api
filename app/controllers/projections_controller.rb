# frozen_string_literal: true

class ProjectionsController < ApplicationController
  def show
    require_admin!
    return if performed?

    render json: { data: payload, errors: [] }
  end

  def update
    require_admin!
    return if performed?

    ActiveRecord::Base.transaction do
      save_finish_rates
      save_reps
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

  def save_finish_rates
    Array(params[:finish_rates]).each do |row|
      raw = row.respond_to?(:to_unsafe_h) ? row.to_unsafe_h : row.to_h
      raw = raw.with_indifferent_access
      level = raw[:level].to_s
      next unless User::LEVELS.include?(level)

      record = LevelFinishRate.find_or_initialize_by(level: level)
      record.finish_rate = raw[:finish_rate].presence || 0
      record.save!
    end
  end

  def save_reps
    Array(params[:reps]).each do |row|
      raw = row.respond_to?(:to_unsafe_h) ? row.to_unsafe_h : row.to_h
      raw = raw.with_indifferent_access
      rep = Rep.find raw[:id]
      rep.update!(
        last_year_revenue: money(raw[:last_year_revenue]),
        projected_revenue: money(raw[:projected_revenue]),
      )
    end
  end

  def money value
    return nil if value.blank?

    value
  end

  def payload
    rates = LevelFinishRate.where(level: User::LEVELS).index_by(&:level)
    {
      finish_rates: User::LEVELS.map do |level|
        { level: level, finish_rate: rates[level]&.finish_rate&.to_f || 0 }
      end,
      reps: Rep.order(:last_name, :first_name).map { |rep| rep_row(rep, rates) },
    }
  end

  def rep_row rep, rates
    rate = rates[rep.level]&.finish_rate
    adjusted = if rep.projected_revenue.present? && rate.present?
      (rep.projected_revenue * rate / 100).round(2).to_f
    end

    {
      id: rep.id,
      full_name: rep.full_name,
      level: rep.level,
      active: rep.active,
      last_year_revenue: rep.last_year_revenue&.to_f,
      projected_revenue: rep.projected_revenue&.to_f,
      finish_rate: rate&.to_f,
      adjusted_projected_revenue: adjusted,
    }
  end
end
