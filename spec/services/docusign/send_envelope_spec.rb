# frozen_string_literal: true

require "rails_helper"

RSpec.describe Docusign::SendEnvelope do
  let(:role) { Role.find_or_create_by!(name: "Admin", code: "admin") }
  let(:recruiter) do
    User.create!(
      email: "packet.recruiter@example.com", password: "pass123!!!",
      first_name: "Jordan", last_name: "Lee", role: role,
    )
  end
  let(:rep_login) do
    User.create!(
      email: "packet.rep@example.com", password: "pass123!!!",
      first_name: "Avery", last_name: "Cole", role: role, level: "Rookie",
    )
  end
  let(:rep) do
    Rep.create!(
      first_name: "Avery", last_name: "Cole", email: "packet.rep@example.com",
      phone: "(801) 555-0100", start_date: "2026-10-20", market: "Park City",
      drivers_license_number: "D1234567", status: "docs_sent",
      recruited_by: recruiter, user: rep_login,
    )
  end
  let(:agreement) do
    OnboardingDocument.create!(
      name: "Rep Agreement", body: "Agree",
      docusign_template_id: Docusign::SendEnvelope::AGREEMENT_TEMPLATE_ID,
    )
  end
  let(:addendum) do
    OnboardingDocument.create!(
      name: "Havn Rookie Addendum", body: "Addendum", level: "Rookie",
      docusign_template_id: "bf7c1049-dc3c-4270-8f63-b0240473d8a8",
    )
  end

  before do
    allow(Docusign::Config).to receive(:configured?).and_return(true)
  end

  it "attaches the level addendum to the Rep Agreement envelope" do
    agreement_delivery = DocumentDelivery.create!(
      rep: rep, onboarding_document: agreement, recipient_email: rep.email, status: "queued",
    )
    addendum_delivery = DocumentDelivery.create!(
      rep: rep, onboarding_document: addendum, recipient_email: rep.email, status: "queued",
    )
    payload = nil
    client = instance_double(Docusign::Client)
    allow(Docusign::Client).to receive(:new).and_return(client)
    allow(client).to receive(:create_envelope) do |body|
      payload = body
      { "envelopeId" => "env-1" }
    end

    described_class.call agreement_delivery

    template_ids = payload[:compositeTemplates].map { |item| item[:serverTemplates].first[:templateId] }
    expect(template_ids).to eq([
      Docusign::SendEnvelope::AGREEMENT_TEMPLATE_ID,
      "bf7c1049-dc3c-4270-8f63-b0240473d8a8",
    ])
    expect(agreement_delivery.reload.docusign_envelope_id).to eq("env-1")
    expect(addendum_delivery.reload.docusign_envelope_id).to eq("env-1")
    expect(addendum_delivery.status).to eq("sent")
  end

  it "sends the agreement alone when no addendum is queued" do
    agreement_delivery = DocumentDelivery.create!(
      rep: rep, onboarding_document: agreement, recipient_email: rep.email, status: "queued",
    )
    payload = nil
    client = instance_double(Docusign::Client)
    allow(Docusign::Client).to receive(:new).and_return(client)
    allow(client).to receive(:create_envelope) do |body|
      payload = body
      { "envelopeId" => "env-2" }
    end

    described_class.call agreement_delivery

    expect(payload[:templateId]).to eq(Docusign::SendEnvelope::AGREEMENT_TEMPLATE_ID)
    expect(payload[:compositeTemplates]).to be_nil
  end
end
