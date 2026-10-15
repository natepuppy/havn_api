# frozen_string_literal: true

module ManagedUsers
  class UpdateUser
    def self.call user_data:, current_user:
      raw  = user_data.respond_to?(:to_unsafe_h) ? user_data.to_unsafe_h : user_data.to_h
      raw  = raw.with_indifferent_access
      user = User.with_deleted.find raw[:id]

      if raw.key?(:deleted_at)
        if raw[:deleted_at].present?
          return [nil, ["You cannot deactivate your own account"]] if user.id == current_user.id

          user.destroy
        else
          user.restore
        end
      end

      if raw[:role].present?
        user.update! role: Role.find_by!(code: raw[:role])
        user.managed_teams.clear if raw[:role] != "manager"
      end

      if user.role&.code == "manager" && raw.key?(:team_ids)
        user.managed_team_ids = Team.where(id: Array(raw[:team_ids])).pluck(:id)
      end

      [user, []]
    rescue ActiveRecord::RecordInvalid => error
      [nil, error.record.errors.full_messages]
    end
  end
end
