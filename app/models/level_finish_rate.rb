# frozen_string_literal: true

class LevelFinishRate < ApplicationRecord
  validates :level, presence: true, uniqueness: true, inclusion: { in: User::LEVELS }
  validates :finish_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
end
