# frozen_string_literal: true

class Rep < ApplicationRecord
  STATUSES = %w[pending docs_sent].freeze
  SHIRT_SIZES = %w[XS S M L XL 2XL 3XL 4XL].freeze

  acts_as_paranoid

  belongs_to :recruited_by, class_name: "User"
  belongs_to :user, optional: true
  has_many :document_deliveries, dependent: :destroy

  validates :first_name, :last_name, :email, :status, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :level, inclusion: { in: User::LEVELS }, allow_nil: true
  validates :email, "valid_email_2/email": true

  def full_name
    [first_name, last_name].compact.join(" ")
  end

  def level
    self[:level].presence || user&.level
  end
end
