# frozen_string_literal: true

module Users
  class PasswordsController < Devise::PasswordsController
    respond_to :json

    def create
      self.resource = resource_class.send_reset_password_instructions resource_params
      if successfully_sent? resource
        render json: { message: "Password reset instructions have been sent to #{resource.email}" }
      else
        render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
      end
    rescue Net::SMTPError, Errno::ECONNREFUSED, Errno::ECONNRESET, SocketError, Timeout::Error, Net::OpenTimeout => error
      Rails.logger.error "Password reset email failed: #{error.class}: #{error.message}"
      render json: { errors: ["We couldn't send the reset email. Try again in a few minutes."] }, status: :service_unavailable
    end

    def update
      self.resource = resource_class.reset_password_by_token resource_params
      if resource.errors.empty?
        render json: { message: "Your password has been updated successfully" }
      else
        render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end
end
