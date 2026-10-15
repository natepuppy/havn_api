# frozen_string_literal: true

class PermissionsController < ApplicationController
  before_action -> { require_permission! :manage_permissions }, except: :index
  before_action :authorize_index, only: :index

  def index
    permissions = PermissionsQuery.call params
    render json: PermissionNormalizer.new(permissions)
  end

  def create
    validator = Permissions::CreateValidator.call params
    errors    = ValidationErrorFormatter.call validator
    records   = []

    if errors.empty?
      records = Permissions::Save.call permissions: Permissions::Build.call(permission_params)
    end

    render json: PermissionNormalizer.new(records, { errors: errors })
  end

  def update
    validator = Permissions::UpdateValidator.call params
    errors    = ValidationErrorFormatter.call validator
    records   = []

    if errors.empty?
      records = Permissions::Save.call(
        permissions:       Permissions::Update.call(permission_params),
        columns_to_update: Permissions::Build::PERMITTED_ATTRIBUTES,
      )
    end

    render json: PermissionNormalizer.new(records, { errors: errors })
  end

  def destroy
    records = Permission.where(id: params[:ids]).destroy_all
    render json: PermissionNormalizer.new(records)
  end

  private

  def permission_params
    params.require :permissions
  end

  def authorize_index
    return if params[:resolved].to_s == "true" && params[:user_id].to_i == current_user.id
    return if Permissions::Access.allowed? current_user, "manage_permissions"

    render json: { errors: ["Unauthorized: Insufficient permissions"] }, status: :forbidden
  end
end
