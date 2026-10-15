# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    respond_to :json

    LOGIN_SUCCESSFUL  = "Logged in successfully."
    LOGOUT_SUCCESSFUL = "logged out successfully"
    NO_SESSION        = "Couldn't find an active session."
    UNAUTHORIZED      = "Unauthorized."

    def verify_token
      if current_user
        render json: {
          status: { code: 200, message: LOGIN_SUCCESSFUL },
          data:   Users::UserNormalizer.new(current_user).as_data,
        }
      else
        render json: { errors: [UNAUTHORIZED] }, status: :unauthorized
      end
    end

    private

    def respond_with resource, _opts = {}
      if current_user
        render json: {
          status: { code: 200, message: LOGIN_SUCCESSFUL },
          data:   Users::UserNormalizer.new(resource).as_data,
          token:  request.env["warden-jwt_auth.token"],
        }
      else
        render json: { errors: [UNAUTHORIZED] }, status: :unauthorized
      end
    end

    def respond_to_on_destroy
      if current_user
        render json: { status: 200, message: LOGOUT_SUCCESSFUL }, status: :ok
      else
        render json: { errors: [NO_SESSION] }, status: :unauthorized
      end
    end
  end
end
