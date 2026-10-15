# frozen_string_literal: true

class TeamsController < ApplicationController
  def index
    unless Permissions::Access.allowed?(current_user, "view_reps") ||
           Permissions::Access.allowed?(current_user, "manage_users")
      return render json: { errors: ["Unauthorized: Insufficient permissions"] }, status: :forbidden
    end

    render json: TeamNormalizer.new(Team.order(:name))
  end

  def create
    require_permission! :manage_users
    return if performed?

    name = params.dig(:team, :name).to_s.strip
    if name.blank?
      return render json: TeamNormalizer.new([], { errors: ["Name can't be blank"] })
    end
    if Team.exists?(name: name)
      return render json: TeamNormalizer.new([], { errors: ["That team has already been added"] })
    end

    render json: TeamNormalizer.new(Team.create!(name: name))
  end
end
