# frozen_string_literal: true

class CreateOnboarding < ActiveRecord::Migration[8.0]
  def change
    create_table :roles do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.timestamps
    end
    add_index :roles, :code, unique: true

    create_table :users do |t|
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.integer :sign_in_count, null: false, default: 0
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string :current_sign_in_ip
      t.string :last_sign_in_ip
      t.string :jti, null: false, default: ""
      t.string :first_name
      t.string :last_name
      t.string :phone
      t.references :role, null: false, foreign_key: true
      t.datetime :deleted_at
      t.timestamps
    end
    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :jti, unique: true
    add_index :users, :deleted_at

    create_table :reps do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.string :phone
      t.string :street
      t.string :city
      t.string :state
      t.string :zip
      t.date :start_date
      t.string :territory
      t.text :notes
      t.string :status, null: false, default: "pending"
      t.references :recruited_by, null: false, foreign_key: { to_table: :users }
      t.datetime :deleted_at
      t.timestamps
    end
    add_index :reps, :email
    add_index :reps, :status
    add_index :reps, :deleted_at

    create_table :onboarding_documents do |t|
      t.string :name, null: false
      t.text :description
      t.text :body, null: false
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0
      t.datetime :deleted_at
      t.timestamps
    end
    add_index :onboarding_documents, :deleted_at

    create_table :document_deliveries do |t|
      t.references :rep, null: false, foreign_key: true
      t.references :onboarding_document, null: false, foreign_key: true
      t.string :recipient_email, null: false
      t.string :status, null: false, default: "queued"
      t.datetime :sent_at
      t.text :error_message
      t.timestamps
    end
    add_index :document_deliveries, :status
  end
end
