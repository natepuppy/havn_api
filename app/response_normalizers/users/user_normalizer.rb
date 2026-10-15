# frozen_string_literal: true

module Users
  class UserNormalizer < BaseResponseNormalizer
    attributes(
      :id,
      :email,
      :first_name,
      :last_name,
      :phone,
      :role_id,
      :deleted_at,
    )

    custom_attributes :role, :full_name, :permissions, :managed_team_ids

    def role object
      object.role&.code
    end

    def full_name object
      [object.first_name, object.last_name].compact.join " "
    end

  def permissions object
    Permissions::Access.map_for object
  end

  def managed_team_ids object
    object.managed_teams.map(&:id)
  end
  end
end
