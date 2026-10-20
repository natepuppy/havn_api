# frozen_string_literal: true

require "rails_helper"

RSpec.describe Docusign::RefreshStatuses do
  let(:role) { Role.find_or_create_by!(name: "Admin", code: "admin") }
  let(:recruiter) do
    User.create!(
      email: "refresh.recruiter@example.com", password: "pass123!!!",
      first_name: "Ada", last_name: "Admin", role: role,
    )
  end
  let(:rep) do
    Rep.create!(
      first_name: "Morgan", last_name: "Hale", email: "refresh.rep@example.com",
      status: "docs_sent", recruited_by: recruiter,
    )
  end
  let(:agreement) { OnboardingDocument.create!(name: "Rep Agreement", body: "Agree") }
  let(:addendum) { OnboardingDocument.create!(name: "Havn Rookie Addendum", body: "Addendum", level: "Rookie") }
  let!(:agreement_delivery) do
    DocumentDelivery.create!(
      rep: rep, onboarding_document: agreement, recipient_email: rep.email,
      status: "sent", docusign_envelope_id: "env-1",
    )
  end
  let!(:addendum_delivery) do
    DocumentDelivery.create!(
      rep: rep, onboarding_document: addendum, recipient_email: rep.email,
      status: "sent", docusign_envelope_id: "env-1",
    )
  end

  before do
    allow(Docusign::Config).to receive(:configured?).and_return(true)
  end

  it "marks every delivery on a completed envelope completed" do
    client = instance_double(Docusign::Client, envelope_statuses: [{ "envelopeId" => "env-1", "status" => "completed" }])
    allow(Docusign::Client).to receive(:new).and_return(client)

    described_class.call deliveries: [agreement_delivery, addendum_delivery]

    expect(agreement_delivery.reload.status).to eq("completed")
    expect(addendum_delivery.reload.status).to eq("completed")
  end

  it "leaves an open envelope as sent" do
    client = instance_double(Docusign::Client, envelope_statuses: [{ "envelopeId" => "env-1", "status" => "sent" }])
    allow(Docusign::Client).to receive(:new).and_return(client)

    described_class.call deliveries: [agreement_delivery]

    expect(agreement_delivery.reload.status).to eq("sent")
  end

  it "does not raise when DocuSign is unavailable" do
    client = instance_double(Docusign::Client)
    allow(client).to receive(:envelope_statuses).and_raise(Docusign::Client::Error, "down")
    allow(Docusign::Client).to receive(:new).and_return(client)

    expect { described_class.call deliveries: [agreement_delivery] }.not_to raise_error
    expect(agreement_delivery.reload.status).to eq("sent")
  end
end
