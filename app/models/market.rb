# frozen_string_literal: true

class Market < ApplicationRecord
  acts_as_paranoid

  validates :name, presence: true, uniqueness: true
end
