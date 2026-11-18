# frozen_string_literal: true

module Reps
  class ReassignDownline
    def self.call(rep:, recruited_by:)
      new(rep, recruited_by).call
    end

    def initialize(rep, recruited_by)
      self.rep = rep
      self.recruited_by = recruited_by
      self.count = 0
      self.error = nil
    end

    def call
      if recruited_by.nil?
        self.error = "Choose a person to receive the downline"
        return self
      end
      if rep.user_id.blank? || Rep.where(recruited_by_id: rep.user_id).none?
        self.count = 0
        return self
      end
      if RecruiterAssignment.downline_includes?(rep: rep, user_id: recruited_by.id)
        self.error = "That person is in this rep's downline"
        return self
      end

      self.count = Rep.where(recruited_by_id: rep.user_id).update_all(
        recruited_by_id: recruited_by.id,
        updated_at: Time.current,
      )
      self
    end

    attr_accessor :count, :error

    private

    attr_accessor :rep, :recruited_by
  end
end
