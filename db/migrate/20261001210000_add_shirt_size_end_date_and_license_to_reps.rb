# frozen_string_literal: true

class AddShirtSizeEndDateAndLicenseToReps < ActiveRecord::Migration[8.0]
  def change
    change_table :reps, bulk: true do |t|
      t.string :shirt_size
      t.date :end_date
      t.string :drivers_license_number
    end
  end
end
