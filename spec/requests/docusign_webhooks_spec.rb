# frozen_string_literal: true

require "rails_helper"

RSpec.describe "DocuSign webhooks", type: :request do
  let(:secret) { "connect-secret" }

  around do |example|
    previous = ENV["DOCUSIGN_CONNECT_KEY"]
    ENV["DOCUSIGN_CONNECT_KEY"] = secret
    example.run
    ENV["DOCUSIGN_CONNECT_KEY"] = previous
  end

  it "marks the matching envelope completed" do
    role = Role.find_or_create_by!(name: "Admin", code: "admin")
    recruiter = User.create!(
      email: "docusign.recruiter@example.com", password: "pass123!!!",
      first_name: "Ada", last_name: "Admin", role: role,
    )
    document = OnboardingDocument.create!(name: "Rep agreement", body: "Agree")
    rep = Rep.create!(
      first_name: "Morgan", last_name: "Hale", email: "morgan.hale@example.com",
      phone: "(801) 555-0110", start_date: "2026-09-02", status: "docs_sent",
      recruited_by: recruiter,
    )
    delivery = DocumentDelivery.create!(
      rep: rep, onboarding_document: document, recipient_email: rep.email,
      status: "sent", docusign_envelope_id: "envelope-1",
    )
    addendum = OnboardingDocument.create!(name: "Havn Rookie Addendum", body: "Addendum", level: "Rookie")
    attached = DocumentDelivery.create!(
      rep: rep, onboarding_document: addendum, recipient_email: rep.email,
      status: "sent", docusign_envelope_id: "envelope-1",
    )
    body = {
      event: "envelope-completed",
      data: { envelopeId: "envelope-1" },
    }.to_json
    signature = Base64.strict_encode64 OpenSSL::HMAC.digest("SHA256", secret, body)

    post "/docusign/webhooks", params: body, headers: {
      "CONTENT_TYPE" => "application/json",
      "X-DocuSign-Signature-1" => signature,
    }

    expect(response).to have_http_status(:ok)
    expect(delivery.reload.status).to eq("completed")
    expect(attached.reload.status).to eq("completed")
  end

  it "rejects a webhook with a bad signature" do
    post "/docusign/webhooks", params: { event: "envelope-completed" }.to_json, headers: {
      "CONTENT_TYPE" => "application/json",
      "X-DocuSign-Signature-1" => "nope",
    }

    expect(response).to have_http_status(:unauthorized)
  end
end
