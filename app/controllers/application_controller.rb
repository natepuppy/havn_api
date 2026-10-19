# frozen_string_literal: true

class ApplicationController < ActionController::API
  include ActionController::MimeResponds
  include PermissionAuthorizable

  respond_to :json

  before_action :authenticate_user!, unless: -> { should_skip_normal_auth? }
  before_action :set_current_attributes, unless: -> { should_skip_normal_auth? }

  rescue_from CanCan::AccessDenied, with: :handle_authorized_action

  private

  def set_current_attributes
    Current.set_from_request request, current_user
  end

  def should_skip_normal_auth?
    request.path.start_with?("/jobs") ||
      request.path == "/up" ||
      request.path == "/users/sign_in" ||
      request.path.start_with?("/users/password") ||
      request.path == "/docusign/webhooks"
  end

  def handle_authorized_action error
    render json: { errors: [error.message] }, status: :unauthorized
  end
end
