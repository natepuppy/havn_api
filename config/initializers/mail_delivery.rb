# frozen_string_literal: true

# Password reset and onboarding mail. Cloud Run has no local mail server, so
# production must set SMTP_ADDRESS (Microsoft 365: smtp.office365.com).
from = ENV.fetch("MAIL_FROM", "Havn Pest Control <onboarding@havnpestcontrol.com>")
ActionMailer::Base.default from: from
Devise.mailer_sender = from

if ENV["SMTP_ADDRESS"].present?
  ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.raise_delivery_errors = true
  ActionMailer::Base.smtp_settings = {
    address: ENV["SMTP_ADDRESS"],
    port: ENV.fetch("SMTP_PORT", "587").to_i,
    domain: ENV.fetch("SMTP_DOMAIN", "havnpestcontrol.com"),
    user_name: ENV["SMTP_USERNAME"],
    password: ENV["SMTP_PASSWORD"],
    authentication: ENV.fetch("SMTP_AUTHENTICATION", "login").to_sym,
    enable_starttls_auto: true,
  }
end
