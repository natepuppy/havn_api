# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable,
         :recoverable,
         :validatable,
         :jwt_authenticatable,
         jwt_revocation_strategy: self

  include Devise::JWT::RevocationStrategies::JTIMatcher

  acts_as_paranoid

  belongs_to :role
  has_one :rep, dependent: :nullify
  has_many :permissions, dependent: :destroy
  has_many :manager_teams, dependent: :destroy
  has_many :managed_teams, through: :manager_teams, source: :team
  has_many :recruited_reps,
           class_name: "Rep",
           foreign_key: :recruited_by_id,
           inverse_of: :recruited_by,
           dependent: :restrict_with_error

  LEVELS = %w[Rookie Veteran Pro].freeze
  HOUSINGS = ["Single housing", "Married housing"].freeze

  scope :recruiters, -> { all }

  validates :level, inclusion: { in: LEVELS }, allow_nil: true
  validates :housing, inclusion: { in: HOUSINGS }, allow_nil: true

  def admin?
    role&.code == "admin"
  end

  def active_for_authentication?
    super && deleted_at.nil?
  end

  def inactive_message
    deleted_at.present? ? :deleted : super
  end
end
