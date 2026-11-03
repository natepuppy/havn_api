# frozen_string_literal: true

class EnsureRepLogins < ActiveRecord::Migration[8.0]
  def up
    Reps::EnsureLogins.call
  end

  def down
  end
end
