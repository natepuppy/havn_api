# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Recruiting goals", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:password) { "pass123!!!" }
  let(:admin_role) { Role.find_or_create_by!(code: "admin") { |role| role.name = "Admin" } }
  let(:rep_role) { Role.find_or_create_by!(code: "rep") { |role| role.name = "Rep" } }
  let(:admin) do
    User.create!(
      email: "goals.admin@example.com", password: password,
      first_name: "Sam", last_name: "Rivera", role: admin_role,
    )
  end
  let(:rep_user) do
    User.create!(
      email: "goals.rep@example.com", password: password,
      first_name: "Casey", last_name: "Nguyen", role: rep_role,
    )
  end

  def auth_header user
    post "/users/sign_in", params: { user: { email: user.email, password: password } }, as: :json
    { "Authorization" => "Bearer #{response.parsed_body['token']}" }
  end

  it "is only available to admins" do
    Permission.create! role: rep_role, action: "view_reps", allowed: true, description: "See the reps list."
    get "/recruiting_goals", headers: auth_header(rep_user)

    expect(response).to have_http_status(:forbidden)
  end

  it "saves the goal, weekly projected revenue, and expenses" do
    headers = auth_header(admin)
    travel_to Date.new(2026, 11, 12) do
      get "/recruiting_goals", headers: headers
      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data["revenue_goal"]).to eq(15_000_000)
      expect(data["weeks"].length).to eq(25)
      expect(data["weeks"].first["starts_on"]).to eq("2026-10-26")
      expect(data["weeks"].last["ends_on"]).to eq("2027-04-24")

      weeks = data["weeks"].map do |week|
        {
          week_number: week["week_number"],
          projected_revenue: week["week_number"] == 2 ? 2_000_000 : nil,
          expenses: { 1 => 1_000, 2 => 2_000, 3 => 500 }[week["week_number"]],
          percent_to_goal_override: week["week_number"] == 1 ? 4.2 : nil,
          percent_into_season_override: nil,
        }
      end

      put "/recruiting_goals",
          params: { revenue_goal: 15_000_000, weeks: weeks },
          headers: headers,
          as: :json

      expect(response).to have_http_status(:ok)
      saved = response.parsed_body["data"]["weeks"].index_by { |week| week["week_number"] }
      expect(saved[2]["projected_revenue"]).to eq(2_000_000)
      expect(saved[2]["percent_to_goal"]).to eq(13.3)
      expect(saved[2]["percent_into_season"]).to eq(8.0)
      expect(saved[1]["percent_to_goal"]).to eq(4.2)
      expect(saved[1]["calculated_percent_to_goal"]).to be_nil

      totals = response.parsed_body["data"]["totals"]
      expect(totals["previous_30_days"]["expenses"]).to eq(3_500)
      expect(totals["previous_30_days"]["projected_revenue"]).to eq(2_000_000)
      expect(totals["previous_30_days"]["percent_to_goal"]).to eq(13.3)
      expect(totals["previous_12_months"]["expenses"]).to eq(3_500)
    end
  end
end
