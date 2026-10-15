# frozen_string_literal: true

class Team < ApplicationRecord
  has_many :manager_teams, dependent: :destroy
  has_many :managers, through: :manager_teams, source: :user

  validates :name, presence: true, uniqueness: true
end
