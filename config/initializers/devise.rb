# frozen_string_literal: true

Devise.setup do |config|
  config.mailer_sender = "onboarding@pest.example"
  require "devise/orm/active_record"

  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.skip_session_storage = [:http_auth, :params_auth]
  config.stretches = Rails.env.test? ? 1 : 12
  config.password_length = 8..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  config.reset_password_within = 6.hours
  config.sign_out_via = :delete
  config.navigational_formats = []
  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other

  config.warden do |manager|
    manager.failure_app = ApiFailureApp
  end

  config.jwt do |jwt|
    jwt.secret = ENV.fetch("DEVISE_JWT_SECRET_KEY") { Rails.application.secret_key_base }
    jwt.dispatch_requests = [["POST", %r{^/users/sign_in$}]]
    jwt.revocation_requests = [["DELETE", %r{^/users/sign_out$}]]
    jwt.expiration_time = 1.month.to_i
  end
end
