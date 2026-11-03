# frozen_string_literal: true

module Reps
  # A rep and their login stay in step. Deactivating either one deactivates both.
  class SyncActivation
    def self.call(active:, rep: nil, user: nil)
      new(active, rep, user).call
    end

    def initialize(active, rep, user)
      self.active = active
      self.rep    = rep
      self.user   = user
    end

    def call
      ActiveRecord::Base.transaction do
        sync_rep
        sync_user
      end
    end

    private

    attr_accessor :active, :rep, :user

    def sync_rep
      record = linked_rep
      return if record.nil? || record.active == active

      record.update! active: active
    end

    def sync_user
      record = linked_user
      return if record.nil?

      if active
        record.recover! if record.deleted?
      elsif !record.deleted?
        record.update_columns deleted_at: Time.current, updated_at: Time.current
      end
    end

    def linked_rep
      return rep if rep
      return if user.nil?

      Rep.find_by user_id: user.id
    end

    def linked_user
      return user if user
      return if rep&.user_id.blank?

      User.with_deleted.find_by id: rep.user_id
    end
  end
end
