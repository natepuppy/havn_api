# frozen_string_literal: true

class RemoveVeteranLevel < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL.squish
      UPDATE reps SET level = 'Pro', updated_at = CURRENT_TIMESTAMP WHERE level = 'Veteran'
    SQL
    execute <<~SQL.squish
      UPDATE users SET level = 'Pro', updated_at = CURRENT_TIMESTAMP WHERE level = 'Veteran'
    SQL
    execute <<~SQL.squish
      UPDATE onboarding_documents
      SET deleted_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP, active = FALSE
      WHERE level = 'Veteran' AND deleted_at IS NULL
    SQL
  end

  def down
  end
end
