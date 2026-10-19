# frozen_string_literal: true

class AddLevelToReps < ActiveRecord::Migration[8.0]
  def up
    add_column :reps, :level, :string
    execute <<~SQL.squish
      UPDATE reps
      SET level = users.level
      FROM users
      WHERE reps.user_id = users.id
        AND users.level IS NOT NULL
        AND (reps.level IS NULL OR reps.level = '')
    SQL
  end

  def down
    remove_column :reps, :level
  end
end
