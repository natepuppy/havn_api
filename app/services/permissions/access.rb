# frozen_string_literal: true

module Permissions
  class Access
    def self.allowed? user, action
      map_for(user)[action.to_s] == true
    end

    def self.map_for user
      return {} if user.blank?

      rows = PermissionsQuery.call user_id: user.id, resolved: true
      Permission::ACTIONS.keys.index_with do |action|
        row = rows.find { |permission| permission.action == action }
        row.present? && row.allowed
      end
    end
  end
end
