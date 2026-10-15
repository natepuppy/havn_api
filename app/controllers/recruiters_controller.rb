# frozen_string_literal: true

class RecruitersController < ApplicationController
  def index
    authorize! :read, User

    recruiters = User.recruiters.includes(:role, :managed_teams).order(:first_name, :last_name)
    render json: Users::UserNormalizer.new(recruiters)
  end
end
