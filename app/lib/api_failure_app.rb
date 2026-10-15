# frozen_string_literal: true

# Custom Devise failure app for API-only usage. Avoids writing to session
# (which is disabled in api_only apps) so unauthenticated requests return
# 401 instead of 500 (DisabledSessionError), and returns a JSON body.
class ApiFailureApp < Devise::FailureApp
  def store_location!
    # No-op: API has no session; avoid ActionDispatch::Request::Session::DisabledSessionError
  end

  def respond
    if request_format == :json || request.format.json?
      self.status        = 401
      self.content_type  = "application/json"
      self.response_body = { errors: ["invalid email or password."], message: i18n_message }.to_json
    else
      super
    end
  end
end
