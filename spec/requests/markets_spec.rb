# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Markets", type: :request do
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

  before do
    Permission.create! role: admin_role, action: "view_reps", allowed: true, description: Permission::ACTIONS.fetch("view_reps")
    Permission.create! role: admin_role, action: "manage_reps", allowed: true, description: Permission::ACTIONS.fetch("manage_reps")
  end

  it "adds a market" do
    post "/users/sign_in", params: { user: { email: admin.email, password: password } }, as: :json
    headers = { "Authorization" => "Bearer #{response.parsed_body["token"]}" }

    post "/markets", params: { markets: [{ name: "Cache Valley" }] }, headers: headers, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["errors"]).to eq([])
    expect(response.parsed_body["data"].first["name"]).to eq("Cache Valley")
    expect(Market.find_by(name: "Cache Valley")).to be_present
  end
end
