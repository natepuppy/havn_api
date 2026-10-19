# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rep onboarding", type: :request do
  let(:password) { "pass123!!!" }
  let(:admin_role) { Role.create! name: "Admin", code: "admin" }
  let(:recruiter_role) { Role.create! name: "Recruiter", code: "recruiter" }
  let(:admin) do
    User.create!(
      email: "admin@example.com",
      password: password,
      first_name: "Sam",
      last_name: "Rivera",
      role: admin_role,
    )
  end
  let(:recruiter) do
    User.create!(
      email: "jordan.lee@example.com",
      password: password,
      first_name: "Jordan",
      last_name: "Lee",
      role: recruiter_role,
    )
  end
  let!(:document) do
    OnboardingDocument.create!(
      name: "Welcome letter",
      description: "First day",
      body: "Welcome aboard.",
      position: 1,
      active: true,
    )
  end

  def auth_header user = admin
    post "/users/sign_in", params: { user: { email: user.email, password: password } }, as: :json
    token = response.parsed_body["token"]
    { "Authorization" => "Bearer #{token}" }
  end

  def grant! role, *actions
    actions.each do |action|
      Permission.create! role: role, action: action, allowed: true, description: Permission::ACTIONS.fetch(action)
    end
  end

  it "creates a rep and sends the selected documents" do
    grant! admin_role, "view_reps", "view_all_reps", "manage_reps"
    Market.create! name: "Wasatch Front"
    recruited_by_id = recruiter.id
    headers = auth_header

    expect {
      perform_enqueued_jobs do
        post "/reps",
             params: {
               reps: [
                 {
                   first_name: "Avery",
                   last_name: "Cole",
                   email: "avery.cole@example.com",
                   phone: "(801) 555-0199",
                   street: "100 Main St",
                   city: "Salt Lake City",
                   state: "UT",
                   zip: "84101",
                   start_date: "2026-10-15",
                   end_date: "2027-10-15",
                   shirt_size: "L",
                   drivers_license_number: "D1234567",
                   market: "Wasatch Front",
                   level: "Rookie",
                   housing: "Single housing",
                   recruited_by_id: recruited_by_id,
                   notes: "Licensed trainee",
                   document_ids: [document.id],
                 },
               ],
             },
             headers: headers,
             as: :json
      end
    }.to change(Rep, :count).by(1)
     .and change(User, :count).by(1)
     .and change(DocumentDelivery, :count).by(1)
     .and change { ActionMailer::Base.deliveries.size }.by(2)

    expect(response).to have_http_status(:ok)
    body = response.parsed_body
    expect(body["errors"]).to eq([])
    rep = body["data"].first
    expect(rep["full_name"]).to eq("Avery Cole")
    expect(rep["recruiter_name"]).to eq("Jordan Lee")
    expect(rep["status"]).to eq("docs_sent")
    expect(rep["shirt_size"]).to eq("L")
    expect(rep["end_date"]).to eq("2027-10-15")
    expect(rep["drivers_license_number"]).to eq("D1234567")
    expect(rep["market"]).to eq("Wasatch Front")
    expect(rep["level"]).to eq("Rookie")
    expect(rep["housing"]).to eq("Single housing")
    expect(rep["documents_sent_count"]).to eq(1)

    mail = ActionMailer::Base.deliveries.find { |message| message.subject.include?("Welcome letter") }
    expect(mail.to).to eq(["avery.cole@example.com"])
    expect(mail.body.encoded).to include("Jordan Lee")

    login = User.find_by! email: "avery.cole@example.com"
    expect(login.role.code).to eq("rep")
    expect(login.level).to eq("Rookie")
    expect(login.housing).to eq("Single housing")
    expect(Rep.find_by!(email: "avery.cole@example.com").user).to eq(login)

    veteran = OnboardingDocument.create!(
      name: "Havn Veteran Addendum", body: "Veteran agreement", level: "Veteran", position: 8,
    )
    rookie = OnboardingDocument.create!(
      name: "Havn Rookie Addendum", body: "Rookie agreement", level: "Rookie", position: 7,
    )
    allow(Docusign::Config).to receive(:template_id).and_return(nil)

    expect {
      perform_enqueued_jobs do
        post "/reps",
             params: {
               reps: [
                 {
                   first_name: "Blake",
                   last_name: "Nguyen",
                   email: "blake.nguyen@example.com",
                   phone: "(801) 555-0188",
                   start_date: "2026-10-20",
                   shirt_size: "M",
                   drivers_license_number: "D7654321",
                   level: "Veteran",
                   housing: "Married housing",
                   recruited_by_id: recruited_by_id,
                   document_ids: [document.id, veteran.id, rookie.id],
                 },
               ],
             },
             headers: headers,
             as: :json
      end
    }.to change(DocumentDelivery, :count).by(2)

    sent_names = DocumentDelivery.joins(:onboarding_document, :rep)
                                 .where(reps: { email: "blake.nguyen@example.com" })
                                 .pluck("onboarding_documents.name")
    expect(sent_names).to contain_exactly("Welcome letter", "Havn Veteran Addendum")
    reset = ActionMailer::Base.deliveries.find { |message| message.subject.downcase.include?("reset") }
    expect(reset.to).to eq(["avery.cole@example.com"])
  end

  it "filters reps by name, recruiter, and market" do
    other = User.create!(
      email: "alex.nguyen@example.com",
      password: password,
      first_name: "Alex",
      last_name: "Nguyen",
      role: recruiter_role,
    )
    Rep.create!(
      first_name: "Morgan", last_name: "Hale", email: "morgan.hale@example.com",
      phone: "(801) 555-0110", market: "Salt Lake Valley", start_date: "2026-09-02",
      status: "pending", recruited_by: recruiter,
    )
    Rep.create!(
      first_name: "Elena", last_name: "Vasquez", email: "elena.vasquez@example.com",
      phone: "(801) 555-0115", market: "Utah County", start_date: "2026-09-22",
      status: "pending", recruited_by: other,
    )
    grant! admin_role, "view_reps", "view_all_reps"
    headers = auth_header

    get "/reps", params: { q: "morgan" }, headers: headers
    expect(response.parsed_body["data"].map { |rep| rep["full_name"] }).to eq(["Morgan Hale"])

    get "/reps", params: { recruited_by_id: [recruiter.id, other.id] }, headers: headers
    expect(response.parsed_body["data"].map { |rep| rep["full_name"] }).to contain_exactly("Morgan Hale", "Elena Vasquez")

    Market.create! name: "Salt Lake Valley"
    Market.create! name: "Utah County"
    get "/reps", params: { market: ["Salt Lake Valley", "Utah County"] }, headers: headers
    expect(response.parsed_body["data"].map { |rep| rep["full_name"] }).to contain_exactly("Morgan Hale", "Elena Vasquez")
    expect(response.parsed_body["markets"]).to include("Salt Lake Valley", "Utah County")
  end

  it "limits a rep to the people they recruited" do
    rep_role = Role.create! name: "Rep", code: "rep"
    grant! rep_role, "view_reps", "manage_reps"
    morgan = User.create!(
      email: "morgan.hale@example.com", password: password,
      first_name: "Morgan", last_name: "Hale", role: rep_role,
    )
    Rep.create!(
      first_name: "Casey", last_name: "Nguyen", email: "casey.nguyen@example.com",
      phone: "(801) 555-0120", market: "Salt Lake Valley", start_date: "2026-11-09",
      status: "pending", recruited_by: morgan,
    )
    other = Rep.create!(
      first_name: "Elena", last_name: "Vasquez", email: "elena.vasquez@example.com",
      phone: "(801) 555-0115", market: "Utah County", start_date: "2026-09-22",
      status: "pending", recruited_by: recruiter,
    )

    headers = auth_header morgan
    get "/reps", headers: headers

    expect(response.parsed_body["data"].map { |rep| rep["full_name"] }).to eq(["Casey Nguyen"])

    get "/reps/#{other.id}", headers: headers
    expect(response).to have_http_status(:not_found)
  end

  it "rejects a new rep when a required document is missing" do
    grant! admin_role, "view_reps", "view_all_reps", "manage_reps"
    document.update! required: true
    optional = OnboardingDocument.create!(
      name: "Vehicle policy",
      body: "Optional vehicle rules.",
      active: true,
      required: false,
    )
    headers = auth_header

    expect {
      post "/reps",
           params: {
             reps: [
               {
                 first_name: "Avery",
                 last_name: "Cole",
                 email: "avery.cole@example.com",
                 phone: "(801) 555-0199",
                 start_date: "2026-10-15",
                 shirt_size: "L",
                 drivers_license_number: "D1234567",
                 level: "Veteran",
                 housing: "Married housing",
                 recruited_by_id: recruiter.id,
                 document_ids: [optional.id],
               },
             ],
           },
           headers: headers,
           as: :json
    }.not_to change(Rep, :count)

    expect(response.parsed_body["errors"].join).to include("required document")
  end

  it "returns the recruiting line for a rep" do
    grant! admin_role, "view_reps", "view_all_reps"
    rep_role = Role.find_or_create_by!(name: "Rep", code: "rep")
    morgan_user = User.create!(
      email: "morgan.hale@example.com", password: password,
      first_name: "Morgan", last_name: "Hale", role: rep_role,
    )
    morgan = Rep.create!(
      first_name: "Morgan", last_name: "Hale", email: "morgan.hale@example.com",
      phone: "(801) 555-0110", market: "Salt Lake Valley", start_date: "2026-09-02",
      status: "docs_sent", recruited_by: recruiter, user: morgan_user,
    )
    casey = Rep.create!(
      first_name: "Casey", last_name: "Nguyen", email: "casey.nguyen@example.com",
      phone: "(801) 555-0120", market: "Salt Lake Valley", start_date: "2026-11-09",
      status: "pending", recruited_by: morgan_user,
    )

    headers = auth_header
    get "/reps/#{casey.id}/recruiting_tree", headers: headers

    expect(response).to have_http_status(:ok)
    root = response.parsed_body["data"].first
    expect(root["name"]).to eq("Jordan Lee")
    expect(root["visible"]).to be false
    expect(root["children"].map { |child| child["name"] }).to eq(["Morgan Hale"])
    morgan_node = root["children"].first
    expect(morgan_node["rep_id"]).to eq(morgan.id)
    expect(morgan_node["visible"]).to be true
    expect(morgan_node["children"].map { |child| child["name"] }).to eq(["Casey Nguyen"])
    expect(morgan_node["children"].first["rep_id"]).to eq(casey.id)
  end

  it "sorts reps by name and filters paperwork, role, and active status" do
    grant! admin_role, "view_reps", "view_all_reps", "manage_reps"
    rep_role = Role.find_or_create_by!(name: "Rep", code: "rep")
    zoe_user = User.create!(
      email: "zoe.young@example.com", password: password,
      first_name: "Zoe", last_name: "Young", role: rep_role,
    )
    amy_user = User.create!(
      email: "amy.adams@example.com", password: password,
      first_name: "Amy", last_name: "Adams", role: admin_role,
    )
    agreement = OnboardingDocument.create!(
      name: "Rep agreement", description: "Agreement", body: "Agree", position: 2, active: true,
    )
    zoe = Rep.create!(
      first_name: "Zoe", last_name: "Young", email: "zoe.young@example.com",
      phone: "(801) 555-0130", start_date: "2026-01-01", status: "docs_sent",
      recruited_by: recruiter, user: zoe_user,
    )
    amy = Rep.create!(
      first_name: "Amy", last_name: "Adams", email: "amy.adams@example.com",
      phone: "(801) 555-0131", start_date: "2026-01-02", status: "pending",
      recruited_by: recruiter, user: amy_user, onboarding_completed: true,
    )
    DocumentDelivery.create!(
      rep: zoe, onboarding_document: agreement, recipient_email: zoe.email, status: "sent",
    )
    headers = auth_header

    get "/reps", headers: headers
    expect(response.parsed_body["data"].map { |row| row["full_name"] }).to eq(["Amy Adams", "Zoe Young"])

    get "/reps", params: { paperwork: "none" }, headers: headers
    expect(response.parsed_body["data"].map { |row| row["full_name"] }).to eq(["Amy Adams"])

    get "/reps", params: { paperwork: "agreement" }, headers: headers
    expect(response.parsed_body["data"].map { |row| row["full_name"] }).to eq(["Zoe Young"])
    expect(response.parsed_body["data"].first["agreement_completed"]).to be true

    get "/reps", params: { paperwork: "completed" }, headers: headers
    expect(response.parsed_body["data"].map { |row| row["full_name"] }).to eq(["Amy Adams"])

    get "/reps", params: { role: "admin" }, headers: headers
    expect(response.parsed_body["data"].map { |row| row["full_name"] }).to eq(["Amy Adams"])

    put "/reps", params: { reps: [{ id: zoe.id, active: false }] }, headers: headers, as: :json
    expect(response.parsed_body["errors"]).to eq([])
    expect(zoe.reload.active).to be false

    get "/reps", headers: headers
    expect(response.parsed_body["data"].map { |row| row["full_name"] }).to eq(["Amy Adams"])

    get "/reps", params: { active: "false" }, headers: headers
    expect(response.parsed_body["data"].map { |row| row["full_name"] }).to eq(["Zoe Young"])
  end
end
