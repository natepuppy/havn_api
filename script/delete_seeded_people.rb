# frozen_string_literal: true

# Hard-deletes the people created by db/seeds/development_seeds.rb.
# Refuses to run unless CONFIRM_DELETE_SEEDED_PEOPLE=production.
# A real rep recruited by a seeded account is pointed at a real login with the same email.

abort "Set CONFIRM_DELETE_SEEDED_PEOPLE=production to run this." unless ENV["CONFIRM_DELETE_SEEDED_PEOPLE"] == "production"

emails = %w[
  admin@example.com
  jordan.lee@example.com
  alex.nguyen@example.com
  morgan.hale@example.com
  priya.shah@example.com
  noah.brooks@example.com
  riley.chen@example.com
  chris.dalton@example.com
  elena.vasquez@example.com
  hannah.ortiz@example.com
  liam.carter@example.com
  sofia.nguyen@example.com
  drew.patel@example.com
  casey.nguyen@example.com
].freeze

reps = Rep.with_deleted.where("lower(email) IN (?)", emails)
users = User.with_deleted.where("lower(email) IN (?)", emails)

seed_user_ids = users.pluck(:id)

linked = Rep.with_deleted.where(user_id: seed_user_ids).where.not(id: reps.select(:id))
if linked.exists?
  puts "Refusing to delete. These reps use a seeded login:"
  linked.find_each { |rep| puts "  id=#{rep.id} email=#{rep.email}" }
  abort
end

ActiveRecord::Base.transaction do
  blocking = Rep.with_deleted.where(recruited_by_id: seed_user_ids).where.not(id: reps.select(:id))
  blocking.find_each do |rep|
    keeper = rep.user if rep.user_id.present? && seed_user_ids.exclude?(rep.user_id)
    keeper ||= Rep.where("lower(email) = ?", rep.email.downcase).where.not(user_id: nil).find { |other| seed_user_ids.exclude?(other.user_id) }&.user
    unless keeper
      puts "Refusing to delete. No real login to attach id=#{rep.id} email=#{rep.email} to."
      raise ActiveRecord::Rollback
    end

    puts "moved rep id=#{rep.id} email=#{rep.email} from #{rep.recruited_by&.email} to #{keeper.email}"
    rep.update! recruited_by: keeper
  end

  deliveries = DocumentDelivery.where(rep_id: reps.select(:id))
  puts "removed #{deliveries.delete_all} document deliveries"

  reps.find_each do |rep|
    rep.destroy_fully!
    puts "removed rep id=#{rep.id} email=#{rep.email}"
  end

  users.find_each do |user|
    user.destroy_fully!
    puts "removed user id=#{user.id} email=#{user.email}"
  end
end

puts "reps remaining: #{Rep.count}"
puts "users remaining: #{User.count}"
