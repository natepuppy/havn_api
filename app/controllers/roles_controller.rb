# frozen_string_literal: true

class RolesController < ApplicationController
  def index
    unless Permissions::Access.allowed?(current_user, "manage_users") ||
           Permissions::Access.allowed?(current_user, "manage_permissions") ||
           Permissions::Access.allowed?(current_user, "view_reps")
      return render json: { errors: ["Unauthorized: Insufficient permissions"] }, status: :forbidden
    end

    render json: RoleNormalizer.new(Role.order(:name))
  end

  def create
    require_permission! :manage_users
    return if performed?

    name = params.dig(:role, :name).to_s.strip
    code = Role.code_for name
    if name.blank? || code.blank?
      return render json: RoleNormalizer.new([], { errors: ["Enter a role name"] })
    end
    if Role.exists?(code: code)
      return render json: RoleNormalizer.new([], { errors: ["That role already exists"] })
    end

    render json: RoleNormalizer.new(Role.create!(name: name, code: code))
  end

  def update
    require_permission! :manage_users
    return if performed?

    role = Role.find_by id: params.dig(:role, :id)
    name = params.dig(:role, :name).to_s.strip
    if role.nil?
      return render json: RoleNormalizer.new([], { errors: ["Choose a role"] })
    end
    if name.blank?
      return render json: RoleNormalizer.new([], { errors: ["Enter a role name"] })
    end

    role.update! name: name
    render json: RoleNormalizer.new(role)
  end
end
