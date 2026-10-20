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

  context "with level addenda" do
    let(:admin_role) { Role.find_or_create_by!(name: "Admin", code: "admin") }
    let(:recruiter_role) { Role.find_or_create_by!(name: "Recruiter", code: "recruiter") }
    let(:admin) do
      User.create!(
        email: "admin.override@example.com", password: "pass123!!!",
        first_name: "Sam", last_name: "Rivera", role: admin_role,
      )
    end
    let(:recruiter) do
      User.create!(
        email: "plain.recruiter@example.com", password: "pass123!!!",
        first_name: "Jordan", last_name: "Lee", role: recruiter_role,
      )
    end
    let(:rep) do
      Rep.create!(
        first_name: "Casey", last_name: "Morgan", email: "casey.morgan@example.com",
        status: "pending", level: "Veteran", recruited_by: recruiter,
      )
    end
    let!(:agreement) do
      OnboardingDocument.create!(
        name: "Rep Agreement", body: "Agree", position: 2,
        docusign_template_id: Docusign::SendEnvelope::AGREEMENT_TEMPLATE_ID,
      )
    end
    let!(:rookie) do
      OnboardingDocument.create!(
        name: "Havn Rookie Addendum", body: "Rookie", level: "Rookie", position: 7,
        docusign_template_id: "bf7c1049-dc3c-4270-8f63-b0240473d8a8",
      )
    end
    let!(:veteran) do
      OnboardingDocument.create!(
        name: "Havn Veteran Addendum", body: "Veteran", level: "Veteran", position: 8,
        docusign_template_id: "3809bfb3-d00d-42bc-a829-7894284d0d23",
      )
    end

    def delivered_names
      rep.document_deliveries.joins(:onboarding_document).pluck("onboarding_documents.name")
    end

    it "lets an admin send a different addendum than the rep's level" do
      described_class.call reps: [rep], document_ids: [agreement.id, rookie.id], actor: admin

      expect(delivered_names).to contain_exactly("Rep Agreement", "Havn Rookie Addendum")
    end

    it "forces the rep's level addendum for a non-admin, even if they pick another" do
      described_class.call reps: [rep], document_ids: [agreement.id, rookie.id], actor: recruiter

      expect(delivered_names).to contain_exactly("Rep Agreement", "Havn Veteran Addendum")
    end

    it "falls back to the rep's level addendum when there is no actor" do
      described_class.call reps: [rep], document_ids: [agreement.id]

      expect(delivered_names).to contain_exactly("Rep Agreement", "Havn Veteran Addendum")
    end
  end
end