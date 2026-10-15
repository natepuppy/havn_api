# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Roles and teams", type: :request do
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

  def auth_header
    post "/users/sign_in", params: { user: { email: admin.email, password: password } }, as: :json
    { "Authorization" => "Bearer #{response.parsed_body['token']}" }
  end

  it "creates a role and assigns the teams a manager covers" do
    %w[manage_users view_reps].each do |action|
      Permission.create! role: admin_role, action: action, allowed: true, description: Permission::ACTIONS.fetch(action)
    end
    headers = auth_header

    post "/roles", params: { role: { name: "Regional Lead" } }, headers: headers, as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["data"]["code"]).to eq("regional_lead")

    post "/roles", params: { role: { name: "Manager" } }, headers: headers, as: :json
    post "/teams", params: { team: { name: "Wasatch Front" } }, headers: headers, as: :json
    team_id = response.parsed_body["data"]["id"]

    post "/managed_users",
         params: {
           users: [
             {
               first_name: "Riley",
               last_name: "Chen",
               email: "riley.chen@example.com",
               role: "manager",
               password: password,
               password_confirmation: password,
               team_ids: [team_id],
             },
           ],
         },
         headers: headers,
         as: :json

    expect(response.parsed_body["errors"]).to eq([])
    expect(response.parsed_body["data"].first["managed_team_ids"]).to eq([team_id])
    expect(User.find_by!(email: "riley.chen@example.com").managed_teams.map(&:name)).to eq(["Wasatch Front"])
  end
end
