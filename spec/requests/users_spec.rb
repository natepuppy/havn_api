# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User management and password reset", type: :request do
  let(:password) { "pass123!!!" }
  let(:admin_role) { Role.create! name: "Admin", code: "admin" }
  let(:rep_role) { Role.create! name: "Rep", code: "rep" }
  let(:admin) do
    User.create!(
      email: "admin@example.com",
      password: password,
      first_name: "Sam",
      last_name: "Rivera",
      role: admin_role,
    )
  end

  def headers
    post "/users/sign_in", params: { user: { email: admin.email, password: password } }, as: :json
    { "Authorization" => "Bearer #{response.parsed_body["token"]}" }
  end

  before do
    rep_role
    %w[manage_users manage_permissions view_reps].each do |action|
      Permission.create! role: admin_role, action: action, allowed: true, description: Permission::ACTIONS.fetch(action)
    end
  end

  it "creates a user, resets their password, and sends a reset code" do
    post "/managed_users",
         params: {
           users: [
             {
               first_name: "Riley",
               last_name: "Chen",
               email: "riley.chen@example.com",
               phone: "(801) 555-0113",
               role: "rep",
               password: "firstpass1",
               password_confirmation: "firstpass1",
             },
           ],
         },
         headers: headers,
         as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["errors"]).to eq([])
    user = User.find_by! email: "riley.chen@example.com"
    expect(user.role.code).to eq("rep")

    post "/managed_users/reset_password",
         params: { user_id: user.id, password: "secondpass1", password_confirmation: "secondpass1" },
         headers: headers,
         as: :json

    expect(response).to have_http_status(:ok)
    expect(user.reload.valid_password?("secondpass1")).to be true

    post "/users/password", params: { user: { email: user.email } }, as: :json
    expect(response).to have_http_status(:ok)
    mail = ActionMailer::Base.deliveries.last
    expect(mail.to).to eq([user.email])
    body = mail.text_part ? mail.text_part.body.decoded : mail.body.decoded
    token = body.lines.map(&:strip).find { |line| line.match?(/\A[A-Za-z0-9_-]{16,}\z/) }
    expect(token).to be_present

    put "/users/password",
        params: {
          user: {
            reset_password_token: token,
            password: "thirdpass1",
            password_confirmation: "thirdpass1",
          },
        },
        as: :json

    expect(response).to have_http_status(:ok)
    expect(user.reload.valid_password?("thirdpass1")).to be true
  end

  it "updates role permissions" do
    post "/permissions",
         params: {
           permissions: [
             { role_id: rep_role.id, action: "view_all_reps", allowed: false, description: "See every rep" },
           ],
         },
         headers: headers,
         as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["errors"]).to eq([])
    expect(Permission.find_by!(role: rep_role, action: "view_all_reps").allowed).to be false
  end
end
