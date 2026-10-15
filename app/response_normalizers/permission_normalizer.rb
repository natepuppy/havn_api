# frozen_string_literal: true

class PermissionNormalizer < BaseResponseNormalizer
  attributes(
    :id,
    :role_id,
    :user_id,
    :action,
    :allowed,
    :description,
  )
end
