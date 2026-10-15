# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Onboarding documents", type: :request do
  let(:password) { "pass123!!!" }
  let(:admin_role) { Role.create! name: "Admin", code: "admin" }
  let(:admin) do
    User.create!(
      email: "admin@example.com",
      password: password,
      first_name: "Sam",
      last_name: "Rivera",
      role: admin_role,
    )
  end
  let!(:document) do
    OnboardingDocument.create!(
      name: "Rep agreement",
      body: "You agree to represent the company.",
      active: true,
      send_by_default: true,
    )
  end

  before do
    Permission.create! role: admin_role, action: "manage_documents", allowed: true,
                       description: Permission::ACTIONS.fetch("manage_documents")
  end

  it "marks a document as not sent by default" do
    post "/users/sign_in", params: { user: { email: admin.email, password: password } }, as: :json
    headers = { "Authorization" => "Bearer #{response.parsed_body["token"]}" }

    put "/onboarding_documents",
        params: { onboarding_documents: [{ id: document.id, send_by_default: false }] },
        headers: headers,
        as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["errors"]).to eq([])
    expect(document.reload.send_by_default).to be false
  end

  it "marks a document required and deletes it" do
    post "/users/sign_in", params: { user: { email: admin.email, password: password } }, as: :json
    headers = { "Authorization" => "Bearer #{response.parsed_body["token"]}" }

    put "/onboarding_documents",
        params: { onboarding_documents: [{ id: document.id, required: true }] },
        headers: headers,
        as: :json

    expect(response).to have_http_status(:ok)
    expect(document.reload.required).to be true

    delete "/onboarding_documents", params: { ids: [document.id].to_json }, headers: headers

    expect(response).to have_http_status(:ok)
    expect(OnboardingDocument.find_by(id: document.id)).to be_nil
    expect(OnboardingDocument.with_deleted.find(document.id).deleted_at).to be_present
  end
end
