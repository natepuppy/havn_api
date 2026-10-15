# frozen_string_literal: true

class RepsQuery
  def self.call relation: Rep.all, params: {}
    new(relation, params).call
  end

  def initialize relation, params
    self.relation = relation
    self.params   = params
  end

  def call
    filter_by_name
    filter_by_recruiter
    filter_by_market
    filter_by_active
    filter_by_paperwork
    filter_by_role
    relation
  end

  private

  attr_accessor :relation, :params

  def filter_by_name
    term = params[:q].to_s.strip
    return if term.blank?

    like = "%#{ActiveRecord::Base.sanitize_sql_like(term)}%"
    self.relation = relation.where(
      "reps.first_name ILIKE :like OR reps.last_name ILIKE :like OR (reps.first_name || ' ' || reps.last_name) ILIKE :like",
      like: like,
    )
  end

  def filter_by_recruiter
    ids = Array(params[:recruited_by_id]).compact_blank
    return if ids.empty?

    self.relation = relation.where recruited_by_id: ids
  end

  def filter_by_market
    names = Array(params[:market]).compact_blank
    return if names.empty?

    self.relation = relation.where market: names
  end

  def filter_by_active
    flag = params[:active].presence || "true"
    return if flag == "all"

    self.relation = relation.where active: flag == "true"
  end

  def filter_by_paperwork
    case params[:paperwork].to_s
    when "none"
      self.relation = relation.where.not id: sent_delivery_rep_ids
    when "sent"
      self.relation = relation.where id: sent_delivery_rep_ids
    when "agreement"
      self.relation = relation.where id: agreement_rep_ids
    when "completed"
      self.relation = relation.where onboarding_completed: true
    end
  end

  def filter_by_role
    code = params[:role].to_s.strip
    return if code.blank?

    self.relation = relation.where user_id: User.joins(:role).where(roles: { code: code }).select(:id)
  end

  def agreement_rep_ids
    sent_delivery_rep_ids.joins(:onboarding_document)
                         .where("onboarding_documents.name ILIKE ?", "%agreement%")
  end

  def sent_delivery_rep_ids
    DocumentDelivery.where(status: "sent").select(:rep_id)
  end
end
