# frozen_string_literal: true

# Addendum documents created before the level column existed have no level,
# so the new-rep form cannot match them to the rep's level. Infer it from the name.
class BackfillLevelOnAddendumDocuments < ActiveRecord::Migration[8.0]
  LEVELS = %w[Rookie Veteran Pro].freeze

  def up
    LEVELS.each do |level|
      execute <<~SQL.squish
        UPDATE onboarding_documents
        SET level = #{connection.quote(level)}
        WHERE level IS NULL
          AND name ILIKE #{connection.quote("%#{level}%addendum%")}
      SQL
    end
  end

  def down
    # Leave the inferred levels in place; removing them would re-break matching.
  end
end
