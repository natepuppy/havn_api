# frozen_string_literal: true

class RepsController < ApplicationController
  def index
    require_permission! :view_reps
    return if performed?

    reps = RepsQuery.call(
      relation: visible_reps.includes(:recruited_by, { user: :role }, document_deliveries: :onboarding_document),
      params:   params,
    ).order("reps.last_name ASC, reps.first_name ASC")
    payload = RepNormalizer.new(reps).to_h
    payload[:markets] = Market.order(:name).pluck(:name)

    render json: payload
  end

  def show
    require_permission! :view_reps
    return if performed?

    rep = visible_reps.includes(:recruited_by, { user: :role }, document_deliveries: :onboarding_document).find params[:id]
    render json: RepNormalizer.new(rep)
  end

  def create
    require_permission! :manage_reps
    return if performed?

    scope_recruiter!
    validator = Reps::CreateValidator.call params
    errors    = ValidationErrorFormatter.call validator
    reps      = []

    if errors.empty?
      reps = Reps::Save.call reps: Reps::Build.call(rep_params)
      Array(rep_params).each_with_index do |param, index|
        raw = param.respond_to?(:to_unsafe_h) ? param.to_unsafe_h : param.to_h
        Reps::SendDocuments.call reps: [reps[index]], document_ids: raw["document_ids"] || raw[:document_ids]
        Reps::ProvisionLogin.call(
          rep:     reps[index],
          level:   raw["level"] || raw[:level],
          housing: raw["housing"] || raw[:housing],
        )
      end
      reps = Rep.includes(:recruited_by, :user, document_deliveries: :onboarding_document).where(id: reps.map(&:id)).order(:id)
    end

    render json: RepNormalizer.new(reps, { errors: errors })
  end

  def recruiting_tree
    require_permission! :view_reps
    return if performed?

    rep = visible_reps.find params[:id]
    render json: { data: Reps::RecruitingTree.call(rep: rep, visible_reps: visible_reps), errors: [] }
  end

  def send_documents
    require_permission! :manage_reps
    return if performed?

    rep = visible_reps.find params[:id]

    document_ids = params[:document_ids].presence || OnboardingDocument.active.pluck(:id)
    Reps::SendDocuments.call reps: [rep], document_ids: document_ids
    rep = Rep.includes(:recruited_by, :user, document_deliveries: :onboarding_document).find rep.id

    render json: RepNormalizer.new(rep)
  end

  def update
    require_permission! :manage_reps
    return if performed?

    validator = Reps::UpdateValidator.call params
    errors    = ValidationErrorFormatter.call validator
    reps      = []

    if errors.empty?
      reps = Array(params[:reps]).map do |row|
        raw = row.respond_to?(:to_unsafe_h) ? row.to_unsafe_h : row.to_h
        raw = raw.with_indifferent_access
        rep = visible_reps.find raw[:id]
        rep.active = raw[:active] if raw.key?(:active)
        rep.onboarding_completed = raw[:onboarding_completed] if raw.key?(:onboarding_completed)
        rep.save!
        rep
      end
      reps = Rep.includes(:recruited_by, { user: :role }, document_deliveries: :onboarding_document).where(id: reps.map(&:id))
    end

    render json: RepNormalizer.new(reps, { errors: errors })
  end

  def destroy
    require_permission! :manage_reps
    return if performed?

    ids  = JSON.parse params[:ids].to_s
    reps = visible_reps.where(id: ids).destroy_all

    render json: RepNormalizer.new(reps)
  end

  private

  def rep_params
    params.require :reps
  end

  def visible_reps
    relation = Rep.all
    return relation if Permissions::Access.allowed? current_user, "view_all_reps"

    relation.where recruited_by_id: current_user.id
  end

  def scope_recruiter!
    return if Permissions::Access.allowed? current_user, "view_all_reps"

    Array(params[:reps]).each do |row|
      row[:recruited_by_id] = current_user.id
    end
  end
end
