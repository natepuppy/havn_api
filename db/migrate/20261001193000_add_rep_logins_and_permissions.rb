# frozen_string_literal: true

class AddRepLoginsAndPermissions < ActiveRecord::Migration[8.0]
  def change
    add_reference :reps, :user, foreign_key: true, index: { unique: true }

    create_table :permissions do |t|
      t.references :role, foreign_key: true
      t.references :user, foreign_key: true
      t.string :action, null: false
      t.boolean :allowed, null: false, default: false
      t.string :description, null: false, default: ""
      t.timestamps
    end

    add_index :permissions,
              [:role_id, :user_id, :action],
              unique: true,
              nulls_not_distinct: true,
              name: "index_permissions_on_scope_and_action"
  end
end
