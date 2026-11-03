# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reps::EnsureLogins do
  let(:recruiter_role) { Role.create! name: "Recruiter", code: "recruiter" }
  let(:recruiter) do
    User.create!(
      email: "ensure.recruiter@example.com", password: "pass123!!!",
      first_name: "Jordan", last_name: "Lee", role: recruiter_role,
    )
  end

  it "creates a login for a rep who does not have one" do
    rep = Rep.create!(
      first_name: "Casey", last_name: "Nguyen", email: "casey.ensure@example.com",
      status: "pending", recruited_by: recruiter,
    )

    expect { described_class.call }.to change(User, :count).by(1)

    user = User.find_by! email: "casey.ensure@example.com"
    expect(user.role.code).to eq("rep")
    expect(rep.reload.user).to eq(user)
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it "does not give a second rep the login that already belongs to someone" do
    role = Role.create! name: "Rep", code: "rep"
    user = User.create!(
      email: "shared.ensure@example.com", password: "pass123!!!",
      first_name: "Dallas", last_name: "Junior", role: role,
    )
    Rep.create!(
      first_name: "Dallas", last_name: "Junior", email: user.email,
      status: "pending", recruited_by: recruiter, user: user,
    )
    extra = Rep.create!(
      first_name: "Dallas", last_name: "Junior", email: user.email,
      status: "pending", recruited_by: recruiter,
    )

    expect { described_class.call }.not_to change(User, :count)
    expect(extra.reload.user_id).to be_nil
  end
end
