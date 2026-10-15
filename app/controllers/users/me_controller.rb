# frozen_string_literal: true

module Users
  class MeController < ApplicationController
    def show
      render json: Users::UserNormalizer.new(current_user)
    end
  end
end
