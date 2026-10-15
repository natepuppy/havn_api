# frozen_string_literal: true

class ManagedUsersController < ApplicationController
  before_action -> { require_permission! :manage_users }

  def index
    users = User.with_deleted.includes(:role, :managed_teams).order(:last_name, :first_name)
    render json: Users::UserNormalizer.new(users)
  end

  def create
    validator = ManagedUsers::CreateValidator.call params
    errors    = ValidationErrorFormatter.call validator
    users     = []

    if errors.empty?
      users, errors = ManagedUsers::Create.call users: params.require(:users)
    end

    render json: Users::UserNormalizer.new(users, { errors: errors })
  end

  def update
    validator = ManagedUsers::UpdateValidator.call params
    errors    = ValidationErrorFormatter.call validator
    user      = nil

    if errors.empty?
      user, errors = ManagedUsers::UpdateUser.call user_data:    params.require(:users).first,
                                                   current_user: current_user
    end

    render json: Users::UserNormalizer.new(user, { errors: errors })
  end

  def reset_password
    user, errors = ManagedUsers::ResetPassword.call user_id:               params[:user_id],
                                                    password:              params[:password],
                                                    password_confirmation: params[:password_confirmation]

    if errors.present?
      return render json: { errors: errors }, status: :unprocessable_entity
    end

    render json: { message: "Password updated successfully", data: Users::UserNormalizer.new(user).as_data }
  end
end
