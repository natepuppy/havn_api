# frozen_string_literal: true

module ManagedUsers
  class Create
    def self.call users:
      created = Array(users).map { |attrs| build attrs }
      [created, []]
    rescue ActiveRecord::RecordInvalid => error
      [[], error.record.errors.full_messages]
    end

    def self.assign_teams user, team_ids
      user.managed_team_ids = Team.where(id: Array(team_ids)).pluck(:id)
    end

    def self.build attrs
      raw = attrs.respond_to?(:to_unsafe_h) ? attrs.to_unsafe_h : attrs.to_h
      raw = raw.with_indifferent_access
      user = User.create!(
        first_name:            raw[:first_name],
        last_name:             raw[:last_name],
        email:                 raw[:email],
        phone:                 raw[:phone],
        role:                  Role.find_by!(code: raw[:role]),
        password:              raw[:password],
        password_confirmation: raw[:password_confirmation],
      )
      assign_teams user, raw[:team_ids] if raw[:role] == "manager"
      user
    end
  end
end
