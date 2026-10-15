# frozen_string_literal: true

module PermissionAuthorizable
  extend ActiveSupport::Concern

  def require_permission! action
    return if Permissions::Access.allowed? current_user, action

    render json: { errors: ["Unauthorized: Insufficient permissions"] }, status: :forbidden
  end
end
