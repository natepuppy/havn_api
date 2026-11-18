# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Projections", type: :request do
  let(:password) { "pass123!!!" }
  let(:admin_role) { Role.find_or_create_by!(code: "admin") { |role| role.name = "Admin" } }
  let(:rep_role) { Role.find_or_create_by!(code: "rep") { |role| role.name = "Rep" } }
  let(:admin) do
    User.create!(
      email: "projections.admin@example.com", password: password,
      first_name: "Sam", last_name: "Rivera", role: admin_role,
    )
  end
  let(:rep_user) do
    User.create!(
      email: "projections.rep@example.com", password: password,
      first_name: "Casey", last_name: "Nguyen", role: rep_role,
    )
  end

  def auth_header user
    post "/users/sign_in", params: { user: { email: user.email, password: password } }, as: :json
    { "Authorization" => "Bearer #{response.parsed_body['token']}" }
  end

  it "is only available to admins" do
    Permission.create! role: rep_role, action: "view_reps", allowed: true, description: "See the reps list."
    get "/projections", headers: auth_header(rep_user)

    expect(response).to have_http_status(:forbidden)
  end

  it "saves revenue and finish rates, then returns the adjusted projection" do
    recruiter = User.create!(
      email: "projections.recruiter@example.com", password: password,
      first_name: "Jordan", last_name: "Lee", role: admin_role,
    )
    rookie = Rep.create!(
      first_name: "Casey", last_name: "Nguyen", email: "casey.projection@example.com",
      status: "pending", level: "Rookie", recruited_by: recruiter,
    )
    pro = Rep.create!(
      first_name: "Morgan", last_name: "Hale", email: "morgan.projection@example.com",
      status: "pending", level: "Pro", recruited_by: recruiter,
    )
    headers = auth_header(admin)

    put "/projections",
        params: {
          finish_rates: [
            { level: "Rookie", finish_rate: 40 },
            { level: "Pro", finish_rate: 70 },
          ],
          reps: [
            { id: rookie.id, last_year_revenue: 12000, projected_revenue: 10000 },
            { id: pro.id, last_year_revenue: nil, projected_revenue: 50000 },
          ],
        },
        headers: headers,
        as: :json

    expect(response).to have_http_status(:ok)
    rows = response.parsed_body["data"]["reps"].index_by { |row| row["id"] }
    expect(rows[rookie.id]["last_year_revenue"]).to eq(12000)
    expect(rows[rookie.id]["adjusted_projected_revenue"]).to eq(4000)
    expect(rows[pro.id]["adjusted_projected_revenue"]).to eq(35000)
    expect(response.parsed_body["data"]["finish_rates"]).to contain_exactly(
      { "level" => "Rookie", "finish_rate" => 40 },
      { "level" => "Pro", "finish_rate" => 70 },
    )
  end
end
