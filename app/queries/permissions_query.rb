# frozen_string_literal: true

class PermissionsQuery
  def self.call params
    new(params).call
  end

  def initialize params
    self.params = params
  end

  def call
    return Permission.where(id: params[:ids]) if params[:ids].present?
    return resolved_for_user if params[:user_id].present? && params[:resolved].to_s == "true"
    return Permission.where(user_id: params[:user_id], role_id: nil).order(:action) if params[:user_id].present?
    return Permission.where(role_id: params[:role_id], user_id: nil).order(:action) if params[:role_id].present?

    Permission.order(:action, :id)
  end

  private

  attr_accessor :params

  def resolved_for_user
    user = User.find params[:user_id]
    Permission.find_by_sql [
      <<~SQL.squish,
        SELECT DISTINCT ON (action) permissions.*
        FROM permissions
        WHERE (user_id = :user_id AND role_id IS NULL)
           OR (role_id = :role_id AND user_id IS NULL)
        ORDER BY action, CASE WHEN user_id IS NOT NULL THEN 0 ELSE 1 END
      SQL
      { user_id: user.id, role_id: user.role_id },
    ]
  end
end
