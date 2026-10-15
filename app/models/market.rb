# frozen_string_literal: true

class Market < ApplicationRecord
  validates :name, presence: true, uniqueness: true
end
