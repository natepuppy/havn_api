# frozen_string_literal: true

class OnboardingDocumentsController < ApplicationController
  def index
    authorize! :read, OnboardingDocument

    documents = OnboardingDocument.order(:position, :name)
    render json: OnboardingDocumentNormalizer.new(documents)
  end

  def show
    document = OnboardingDocument.find params[:id]
    authorize! :read, document

    render json: OnboardingDocumentNormalizer.new(document)
  end

  def create
    authorize! :create, OnboardingDocument

    validator = OnboardingDocuments::CreateValidator.call params
    errors    = ValidationErrorFormatter.call validator
    documents = []

    if errors.empty?
      documents = OnboardingDocuments::Save.call(
        documents: OnboardingDocuments::Build.call(document_params),
      )
    end

    render json: OnboardingDocumentNormalizer.new(documents, { errors: errors })
  end

  def update
    authorize! :update, OnboardingDocument

    validator = OnboardingDocuments::UpdateValidator.call params
    errors    = ValidationErrorFormatter.call validator
    documents = []

    if errors.empty?
      updated = OnboardingDocuments::Update.call document_params
      documents = OnboardingDocuments::Save.call(
        documents:         updated,
        columns_to_update: OnboardingDocuments::Build::PERMITTED_ATTRIBUTES,
      )
    end

    render json: OnboardingDocumentNormalizer.new(documents, { errors: errors })
  end

  def destroy
    authorize! :destroy, OnboardingDocument

    ids       = JSON.parse params[:ids].to_s
    documents = OnboardingDocument.where(id: ids).destroy_all

    render json: OnboardingDocumentNormalizer.new(documents)
  end

  private

  def document_params
    params.require :onboarding_documents
  end
end
