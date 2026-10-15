# frozen_string_literal: true

class Role < ApplicationRecord
  CODES = %w[admin recruiter office rep].freeze
  RECRUITER_CODES = %w[admin recruiter office rep].freeze

  has_many :users, dependent: :restrict_with_error
  has_many :permissions, dependent: :restrict_with_error

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true

  def self.code_for name
    name.to_s.strip.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/\A_|_\z/, "")
  end
end
