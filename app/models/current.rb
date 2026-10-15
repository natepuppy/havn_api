# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes
  attribute :user, :request_method, :request_path, :request_params,
            :request_ip, :user_name, :user_email, :previous_entities,
            :current_entities

  attribute :errors, default: -> { [] }

  def set_from_request request, user
    self.user           = user
    self.request_method = request.method
    self.request_path   = request.path
    self.request_params = request.params
    self.request_ip     = request.remote_ip
    self.user_name      = [user&.first_name, user&.last_name].compact.join(" ")
    self.user_email     = user&.email
    self.errors         = []
  end

  def set_previous_and_current_entities previous_entities:, current_entities:
    self.previous_entities = previous_entities
    self.current_entities  = current_entities
  end
end
