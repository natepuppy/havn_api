# frozen_string_literal: true

Role::CODES.each do |code|
  Role.find_or_create_by!(code: code) { |role| role.name = code.titleize }
end

manager = Role.find_or_create_by!(code: "manager") { |role| role.name = "Manager" }
%w[view_reps view_all_reps manage_reps].each do |action|
  permission = Permission.find_or_initialize_by role: manager, user_id: nil, action: action
  next unless permission.new_record?

  permission.allowed     = true
  permission.description = Permission::ACTIONS.fetch(action)
  permission.save!
end

["Wasatch Front", "Southern Utah", "Davis Weber"].each do |name|
  Team.find_or_create_by! name: name
end

Permission::DEFAULTS.each do |code, actions|
  role = Role.find_by! code: code
  Permission::ACTIONS.each do |action, description|
    permission = Permission.find_or_initialize_by role: role, user_id: nil, action: action
    next unless permission.new_record?

    permission.allowed     = actions.include? action
    permission.description = description
    permission.save!
  end
end

password = ENV.fetch "DEV_DEFAULT_PASSWORD"

[
  { email: "admin@example.com", first_name: "Sam", last_name: "Rivera", role: "admin", phone: "(801) 555-0100" },
  { email: "jordan.lee@example.com", first_name: "Jordan", last_name: "Lee", role: "recruiter", phone: "(801) 555-0101" },
  { email: "alex.nguyen@example.com", first_name: "Alex", last_name: "Nguyen", role: "recruiter", phone: "(801) 555-0102" },
].each do |attrs|
  user = User.find_or_initialize_by email: attrs[:email]
  user.assign_attributes(
    first_name: attrs[:first_name],
    last_name:  attrs[:last_name],
    phone:      attrs[:phone],
    role:       Role.find_by!(code: attrs[:role]),
    password:   password,
  )
  user.save!
end

documents = [
  {
    position: 1,
    name: "Welcome letter",
    description: "First-day note for a new pest control rep.",
    body: <<~BODY.strip,
      Welcome aboard.

      You are joining as a field representative. Your recruiter will walk you through your first route, the service protocols, and how to log each stop.

      Bring a photo ID and your driver's license on day one. Wear closed-toe shoes. We will issue your uniform, tablet, and starter chemical kit after this packet is signed.
    BODY
  },
  {
    position: 2,
    name: "Rep agreement",
    description: "Role, territory, and conduct expectations.",
    body: <<~BODY.strip,
      Representative agreement

      You agree to represent the company on assigned residential and commercial pest accounts. You will follow label directions, state applicator rules, and the service checklist for every visit.

      Territory assignments can change. Customer information, route lists, and pricing stay company property. Do not share them outside the company.
    BODY
  },
  {
    position: 3,
    name: "Direct deposit authorization",
    description: "Payroll setup for commissions and hourly pay.",
    body: <<~BODY.strip,
      Direct deposit authorization

      Complete your bank name, routing number, and account number and return this form before your first payroll date. Commissions are calculated from completed, paid services on your rep number.

      Attach a voided check or a bank letter if this is a new account.
    BODY
  },
  {
    position: 4,
    name: "Applicator license checklist",
    description: "What to file before treating on your own.",
    body: <<~BODY.strip,
      Pesticide applicator license checklist

      1. Confirm your state applicator or trainee credential.
      2. Send a photo of the license to your recruiter.
      3. Complete the label and safety orientation before solo routes.
      4. Carry the license and SDS access on every job.

      You may ride along before the license is on file. You may not apply product on your own until the office marks this checklist complete.
    BODY
  },
  {
    position: 5,
    send_by_default: false,
    name: "Vehicle and equipment policy",
    description: "Truck, sprayer, and inventory rules.",
    body: <<~BODY.strip,
      Vehicle and equipment policy

      Company vehicles and sprayers are for service calls only. Log mileage, fuel, and product used at the end of each day. Report spills, missing inventory, or vehicle damage the same day.

      Personal errands in a company vehicle are not allowed. Return keys and inventory if you leave the company.
    BODY
  },
  {
    position: 6,
    send_by_default: false,
    name: "Safety acknowledgment",
    description: "Label, PPE, and customer-home safety rules.",
    body: <<~BODY.strip,
      Safety acknowledgment

      I will read the product label before each application, wear the required PPE, and keep people and pets out of treated areas for the time on the label. I will not apply a product I have not been trained on.

      I will report bites, stings, chemical exposure, and driving incidents to my recruiter immediately.
    BODY
  },
]

documents.each do |attrs|
  document = OnboardingDocument.find_or_initialize_by name: attrs[:name]
  document.assign_attributes attrs
  document.save!
end

[
  { first_name: "Morgan", last_name: "Hale", email: "morgan.hale@example.com", phone: "(801) 555-0110", market: "Salt Lake Valley", recruited_by: "jordan.lee@example.com", start_date: "2026-09-02", status: "docs_sent", street: "410 E 200 S", city: "Salt Lake City", state: "UT", zip: "84111" },
  { first_name: "Priya", last_name: "Shah", email: "priya.shah@example.com", phone: "(801) 555-0111", market: "Salt Lake Valley", recruited_by: "jordan.lee@example.com", start_date: "2026-09-16", status: "docs_sent", street: "88 S State St", city: "Salt Lake City", state: "UT", zip: "84111" },
  { first_name: "Noah", last_name: "Brooks", email: "noah.brooks@example.com", phone: "(801) 555-0112", market: "Davis County", recruited_by: "jordan.lee@example.com", start_date: "2026-10-06", status: "docs_sent", street: "12 N Main St", city: "Farmington", state: "UT", zip: "84025" },
  { first_name: "Riley", last_name: "Chen", email: "riley.chen@example.com", phone: "(801) 555-0113", market: "Ogden", recruited_by: "jordan.lee@example.com", start_date: "2026-10-20", status: "pending", street: "255 25th St", city: "Ogden", state: "UT", zip: "84401" },
  { first_name: "Chris", last_name: "Dalton", email: "chris.dalton@example.com", phone: "(801) 555-0114", market: "Utah County", recruited_by: "alex.nguyen@example.com", start_date: "2026-09-08", status: "pending", street: "44 W Center St", city: "Provo", state: "UT", zip: "84601" },
  { first_name: "Elena", last_name: "Vasquez", email: "elena.vasquez@example.com", phone: "(801) 555-0115", market: "Utah County", recruited_by: "alex.nguyen@example.com", start_date: "2026-09-22", status: "docs_sent", street: "900 N University Ave", city: "Provo", state: "UT", zip: "84604" },
  { first_name: "Hannah", last_name: "Ortiz", email: "hannah.ortiz@example.com", phone: "(801) 555-0116", market: "Davis County", recruited_by: "alex.nguyen@example.com", start_date: "2026-10-13", status: "docs_sent", street: "70 S Main St", city: "Bountiful", state: "UT", zip: "84010" },
  { first_name: "Liam", last_name: "Carter", email: "liam.carter@example.com", phone: "(435) 555-0117", market: "St. George", recruited_by: "jordan.lee@example.com", start_date: "2026-08-18", status: "docs_sent", street: "15 E St George Blvd", city: "St. George", state: "UT", zip: "84770" },
  { first_name: "Sofia", last_name: "Nguyen", email: "sofia.nguyen@example.com", phone: "(435) 555-0118", market: "St. George", recruited_by: "alex.nguyen@example.com", start_date: "2026-11-02", status: "pending", street: "120 W Tabernacle St", city: "St. George", state: "UT", zip: "84770" },
  { first_name: "Drew", last_name: "Patel", email: "drew.patel@example.com", phone: "(801) 555-0119", market: "Ogden", recruited_by: "admin@example.com", start_date: "2026-10-27", status: "docs_sent", street: "300 Washington Blvd", city: "Ogden", state: "UT", zip: "84401" },
  { first_name: "Casey", last_name: "Nguyen", email: "casey.nguyen@example.com", phone: "(801) 555-0120", market: "Salt Lake Valley", recruited_by: "morgan.hale@example.com", start_date: "2026-11-09", status: "pending", street: "18 E 400 S", city: "Salt Lake City", state: "UT", zip: "84111" },
].each do |attrs|
  Market.find_or_create_by! name: attrs[:market]
  recruiter = User.find_by! email: attrs[:recruited_by]
  rep = Rep.find_or_initialize_by email: attrs[:email]
  rep.assign_attributes(
    first_name:      attrs[:first_name],
    last_name:       attrs[:last_name],
    phone:           attrs[:phone],
    street:          attrs[:street],
    city:            attrs[:city],
    state:           attrs[:state],
    zip:             attrs[:zip],
    start_date:      attrs[:start_date],
    market:          attrs[:market],
    status:          attrs[:status],
    recruited_by:    recruiter,
    notes:           "Seeded onboarding record.",
  )
  rep.save!
  Reps::ProvisionLogin.call rep: rep, password: password, send_reset: false

  next unless attrs[:status] == "docs_sent"

  OnboardingDocument.active.find_each do |document|
    delivery = DocumentDelivery.find_or_initialize_by rep: rep, onboarding_document: document
    delivery.assign_attributes(
      recipient_email: rep.email,
      status:          "sent",
      sent_at:         delivery.sent_at || Time.current,
    )
    delivery.save!
  end
end

Rep.where(user_id: nil).find_each do |rep|
  Reps::ProvisionLogin.call rep: rep, password: password, send_reset: false
end

puts "Dev login: admin@example.com / #{password}"
puts "Rep logins use the same password. Morgan Hale only sees reps she recruited."
