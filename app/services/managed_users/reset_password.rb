# frozen_string_literal: true

module ManagedUsers
  class ResetPassword
    def self.call user_id:, password:, password_confirmation:
      new(user_id, password, password_confirmation).call
    end

    def initialize user_id, password, password_confirmation
      self.user_id               = user_id
      self.password              = password
      self.password_confirmation = password_confirmation
    end

    def call
      user = User.find_by id: user_id
      return [nil, ["User not found"]] if user.blank?

      if user.reset_password password, password_confirmation
        [user, []]
      else
        [nil, user.errors.full_messages]
      end
    end

    private

    attr_accessor :user_id, :password, :password_confirmation
  end
end
