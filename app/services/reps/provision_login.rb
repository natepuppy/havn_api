# frozen_string_literal: true

module Reps
  class ProvisionLogin
    def self.call rep:, password: nil, send_reset: true, level: nil, housing: nil
      new(rep, password, send_reset, level, housing).call
    end

    def initialize rep, password, send_reset, level, housing
      self.rep        = rep
      self.password   = password
      self.send_reset = send_reset
      self.level      = level
      self.housing    = housing
    end

    def call
      user = User.with_deleted.find_by email: rep.email.to_s.strip.downcase
      created = user.nil?

      if created
        chosen = password.presence || "#{SecureRandom.hex(8)}aA1"
        user = User.create!(
          email:      rep.email,
          first_name: rep.first_name,
          last_name:  rep.last_name,
          phone:      rep.phone,
          level:      level,
          housing:    housing,
          role:       Role.find_or_create_by!(code: "rep") { |role| role.name = "Rep" },
          password:   chosen,
        )
      else
        user.restore if user.deleted?
        owned_by_another_rep = Rep.where(user_id: user.id).where.not(id: rep.id).exists?
        unless owned_by_another_rep
          user.update!(
            first_name: rep.first_name,
            last_name:  rep.last_name,
            phone:      rep.phone.presence || user.phone,
            level:      level.presence || user.level,
            housing:    housing.presence || user.housing,
          )
        end
      end

      rep.update! user: user if rep.user_id != user.id && !Rep.where(user_id: user.id).where.not(id: rep.id).exists?
      user.send_reset_password_instructions if created && send_reset
      user
    end

    private

    attr_accessor :rep, :password, :send_reset, :level, :housing
  end
end
