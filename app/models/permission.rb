# frozen_string_literal: true

class Permission < ApplicationRecord
  ACTIONS = {
    "view_reps"          => "See the reps list.",
    "view_all_reps"      => "See every rep, not only the ones you recruited.",
    "manage_reps"        => "Onboard a rep and send their documents.",
    "manage_documents"   => "Add documents and choose which ones are active.",
    "manage_users"       => "Create users, change roles, deactivate accounts, and reset passwords.",
    "manage_permissions" => "Change what each role and user is allowed to do.",
  }.freeze

  DEFAULTS = {
    "admin"     => ACTIONS.keys,
    "office"    => %w[view_reps view_all_reps manage_reps manage_documents],
    "recruiter" => %w[view_reps view_all_reps manage_reps],
    "rep"       => %w[view_reps manage_reps],
  }.freeze

  belongs_to :role, optional: true
  belongs_to :user, optional: true

  validates :action, inclusion: { in: ACTIONS.keys }
  validate :scope_present

  private

  def scope_present
    return if role_id.present? ^ user_id.present?

    errors.add :base, "A permission belongs to a role or a user"
  end
end
