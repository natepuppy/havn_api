# frozen_string_literal: true

class ManagerTeam < ApplicationRecord
  belongs_to :user
  belongs_to :team

  validates :team_id, uniqueness: { scope: :user_id }
end
