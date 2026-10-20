# frozen_string_literal: true

class MarketsController < ApplicationController
  def index
    require_permission! :view_reps
    return if performed?

    render json: MarketNormalizer.new(Market.order(:name))
  end

  def create
    require_permission! :manage_reps
    return if performed?

    validator = Markets::CreateValidator.call params
    errors    = ValidationErrorFormatter.call validator
    markets   = []

    if errors.empty?
      markets = Array(params[:markets]).map do |row|
        raw = row.respond_to?(:to_unsafe_h) ? row.to_unsafe_h : row.to_h
        Market.create! name: raw["name"].to_s.strip
      end
    end

    render json: MarketNormalizer.new(markets, { errors: errors })
  end

  def destroy
    require_permission! :manage_reps
    return if performed?

    ids     = JSON.parse params[:ids].to_s
    markets = Market.where(id: ids).destroy_all

    render json: MarketNormalizer.new(markets)
  end
end
