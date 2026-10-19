# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reps::SendDocuments do
  it "attaches the level addendum when the rep has no login yet" do
    role = Role.find_or_create_by!(name: "Admin", code: "admin")
    recruiter = User.create!(
      email: "level.recruiter@example.com", password: "pass123!!!",
      first_name: "Jordan", last_name: "Lee", role: role,
    )
    User.create!(
      email: "same.rep@example.com", password: "pass123!!!",
      first_name: "Existing", last_name: "Login", role: role, level: "Rookie",
    )
    rep = Rep.create!(
      first_name: "Nathan", last_name: "Clark", email: "same.rep@example.com",
      status: "pending", level: "Veteran", recruited_by: recruiter,
    )
    agreement = OnboardingDocument.create!(
      name: "Rep Agreement", body: "Agree",
      docusign_template_id: Docusign::SendEnvelope::AGREEMENT_TEMPLATE_ID,
    )
    addendum = OnboardingDocument.create!(
      name: "Havn Veteran Addendum", body: "Addendum", level: "Veteran",
      docusign_template_id: "3809bfb3-d00d-42bc-a829-7894284d0d23",
    )

    expect {
      described_class.call reps: [rep], document_ids: [agreement.id, addendum.id]
    }.to have_enqueued_job(SendOnboardingDocumentJob).exactly(1).times

    names = rep.document_deliveries.joins(:onboarding_document).pluck("onboarding_documents.name")
    expect(names).to contain_exactly("Rep Agreement", "Havn Veteran Addendum")
  end
end