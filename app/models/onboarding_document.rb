# frozen_string_literal: true

class OnboardingDocument < ApplicationRecord
  acts_as_paranoid

  has_many :document_deliveries

  validates :name, :body, presence: true
  validates :level, inclusion: { in: User::LEVELS }, allow_nil: true

  scope :active, -> { where(active: true) }
  scope :send_by_default, -> { active.where(send_by_default: true) }

  def for_level? level
    self.level.blank? || self.level == level
  end

  def agreement?
    level.present? || name.to_s.match?(/agreement|addendum/i)
  end

  def docusign_template_id
    self[:docusign_template_id].presence || fallback_template_id
  end

  def docusign?
    docusign_template_id.present?
  end

  private

  def fallback_template_id
    return unless agreement?

    Docusign::Config.template_id.presence
  end
end
