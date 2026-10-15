# frozen_string_literal: true

class OnboardingDocument < ApplicationRecord
  acts_as_paranoid

  has_many :document_deliveries

  validates :name, :body, presence: true

  scope :active, -> { where(active: true) }
  scope :send_by_default, -> { active.where(send_by_default: true) }
end
