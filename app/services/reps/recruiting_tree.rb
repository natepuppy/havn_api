# frozen_string_literal: true

module Reps
  class RecruitingTree
    def self.call(rep:, visible_reps:)
      new(rep, visible_reps).call
    end

    def initialize(rep, visible_reps)
      @rep = rep
      @visible_ids = visible_reps.pluck(:id)
      @reps_by_recruiter = Rep.where(id: tree_rep_ids).includes(user: :role).group_by(&:recruited_by_id)
    end

    def call
      root = root_user
      return [] if root.nil?

      [node_for(user: root, rep: root.rep)].compact
    end

    private

    attr_reader :rep, :visible_ids, :reps_by_recruiter

    def tree_rep_ids
      @tree_rep_ids ||= (ancestor_chain.map(&:id) + visible_ids).uniq
    end

    def ancestor_chain
      @ancestor_chain ||= begin
        chain = []
        current = rep
        seen = {}
        while current && !seen[current.id]
          seen[current.id] = true
          chain << current
          current = current.recruited_by&.rep
        end
        chain
      end
    end

    def root_user
      ancestor_chain.last&.recruited_by
    end

    def node_for(user:, rep:, seen: {})
      return if user && seen[user.id]

      seen = seen.merge(user.id => true) if user
      record = rep || user&.rep
      children = Array(reps_by_recruiter[user&.id]).sort_by(&:full_name).filter_map do |child|
        node_for user: child.user, rep: child, seen: seen
      end

      {
        key:       record ? "rep-#{record.id}" : "user-#{user.id}",
        user_id:   user&.id,
        rep_id:    record&.id,
        name:      record&.full_name.presence || [user&.first_name, user&.last_name].compact.join(" "),
        email:     record&.email || user&.email,
        phone:     record&.phone || user&.phone,
        role:      user&.role&.name || "Rep",
        market: record&.market,
        visible:   record.present? && visible_ids.include?(record.id),
        children:  children,
      }
    end
  end
end
