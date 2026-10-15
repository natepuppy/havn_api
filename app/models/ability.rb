# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize user
    return if user.blank?

    can :read, :all

    if Permissions::Access.allowed? user, "manage_reps"
      can :create, Rep
      can :update, Rep
      can :destroy, Rep
    end

    if Permissions::Access.allowed? user, "manage_documents"
      can :manage, OnboardingDocument
    end

    if Permissions::Access.allowed? user, "manage_users"
      can :manage, User
    end
  end
end
