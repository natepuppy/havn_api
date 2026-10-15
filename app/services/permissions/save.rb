# frozen_string_literal: true

module Permissions
  class Save
    def self.call permissions:, columns_to_update: nil
      return if permissions.blank?

      options = {}
      options[:on_duplicate_key_update] = columns_to_update if columns_to_update.present?
      result = Permission.import permissions, **options
      Permission.where(id: result.ids).order(:action, :id)
    end
  end
end
