# frozen_string_literal: true

module Reps
  class RecruiterAssignment
    def self.cycle?(rep:, recruited_by_id:)
      new(rep).cycle?(recruited_by_id)
    end

    def self.downline_includes?(rep:, user_id:)
      new(rep).downline_includes?(user_id)
    end

    def initialize rep
      self.rep = rep
    end

    def cycle? recruited_by_id
      return false if recruited_by_id.blank?
      return true if rep.user_id.present? && rep.user_id == recruited_by_id.to_i

      seen = {}
      current_id = recruited_by_id.to_i
      while current_id && !seen[current_id]
        return true if rep.user_id.present? && current_id == rep.user_id

        seen[current_id] = true
        current_id = Rep.find_by(user_id: current_id)&.recruited_by_id
      end
      false
    end

    def downline_includes? user_id
      return false if rep.user_id.blank? || user_id.blank?
      return true if rep.user_id == user_id.to_i

      seen = {}
      frontier = [rep.user_id]
      target = user_id.to_i
      while (current = frontier.shift)
        next if seen[current]

        seen[current] = true
        child_ids = Rep.where(recruited_by_id: current).pluck(:user_id).compact
        return true if child_ids.include?(target)

        frontier.concat child_ids
      end
      false
    end

    private

    attr_accessor :rep
  end
end
