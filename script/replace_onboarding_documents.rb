# frozen_string_literal: true

# Keeps the four DocuSign documents and soft-deletes every other onboarding document.
# Run through script/replace_onboarding_documents.sh so the database connection is set.

documents = [
  {
    position: 1,
    name: "Rep Agreement",
    description: "Sent to every rep. The level addendum is attached with it.",
    body: <<~BODY.strip,
      Representative agreement

      You agree to represent the company on assigned residential and commercial pest accounts. You will follow label directions, state applicator rules, and the service checklist for every visit.

      Territory assignments can change. Customer information, route lists, and pricing stay company property. Do not share them outside the company.
    BODY
    active: true,
    send_by_default: true,
    required: true,
    level: nil,
    docusign_template_id: "736474c4-34c8-4f48-a4a3-8727bd55a9ba",
  },
  {
    position: 2,
    name: "Havn Rookie Addendum",
    description: "Agreement sent to Rookie reps.",
    body: "Sent through DocuSign when the rep's level is Rookie.",
    active: true,
    send_by_default: false,
    required: false,
    level: "Rookie",
    docusign_template_id: "bf7c1049-dc3c-4270-8f63-b0240473d8a8",
  },
  {
    position: 3,
    name: "Havn Veteran Addendum",
    description: "Agreement sent to Veteran reps.",
    body: "Sent through DocuSign when the rep's level is Veteran.",
    active: true,
    send_by_default: false,
    required: false,
    level: "Veteran",
    docusign_template_id: "3809bfb3-d00d-42bc-a829-7894284d0d23",
  },
  {
    position: 4,
    name: "Havn Pro Addendum",
    description: "Agreement sent to Pro reps.",
    body: "Sent through DocuSign when the rep's level is Pro.",
    active: true,
    send_by_default: false,
    required: false,
    level: "Pro",
    docusign_template_id: "e8048ca0-1a5b-4cf7-bed9-6c5c0349eadb",
  },
]

missing = %w[level docusign_template_id] - OnboardingDocument.column_names
if missing.any?
  abort "onboarding_documents is missing #{missing.join(", ")}. Run db:migrate before this script."
end

kept_ids = documents.map do |attrs|
  document = OnboardingDocument.with_deleted.find_by(name: attrs[:name])
  if document.nil? && attrs[:name] == "Rep Agreement"
    document = OnboardingDocument.with_deleted.find_by(name: "Rep agreement")
  end
  document ||= OnboardingDocument.new
  document.restore if document.persisted? && document.deleted?
  document.assign_attributes attrs
  document.save!
  puts "kept id=#{document.id} name=#{document.name} level=#{document.level || "-"} template=#{document.docusign_template_id}"
  document.id
end

OnboardingDocument.where.not(id: kept_ids).find_each do |document|
  puts "removed id=#{document.id} name=#{document.name}"
  document.destroy!
end

puts "active documents: #{OnboardingDocument.order(:position, :id).pluck(:name).join(", ")}"
