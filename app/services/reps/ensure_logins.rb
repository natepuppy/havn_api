# frozen_string_literal: true

module Reps
  # Every rep record should be able to sign in. Create a login when the email
  # has none, or attach an existing login that is not already tied to another rep.
  class EnsureLogins
    def self.call
      new.call
    end

    def call
      Role.find_or_create_by!(code: "rep") { |role| role.name = "Rep" }

      Rep.find_each do |rep|
        email = rep.email.to_s.strip.downcase
        next if email.blank?

        user = User.with_deleted.find_by email: email
        if user.nil?
          ProvisionLogin.call rep: rep, send_reset: false
          next
        end

        user.recover! if user.deleted?
        next if rep.user_id == user.id
        next if Rep.where(user_id: user.id).where.not(id: rep.id).exists?

        rep.update! user: user
      end
    end
  end
end
