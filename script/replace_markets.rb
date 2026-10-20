# frozen_string_literal: true

# Removes every other market, then leaves only these four active.
names = ["Orlando", "Jacksonville", "Tampa", "Houston"]

unless Market.column_names.include?("deleted_at")
  abort "markets is missing deleted_at. Run db:migrate before this script."
end

Market.where.not(name: names).find_each do |market|
  puts "removed id=#{market.id} name=#{market.name}"
  market.destroy!
end

Market.with_deleted.where.not(name: names).delete_all!

names.each do |name|
  market = Market.find_by(name: name) || Market.create!(name: name)
  puts "kept id=#{market.id} name=#{market.name}"
end

puts "active markets: #{Market.order(:name).pluck(:name).join(", ")}"
puts "rows in markets: #{Market.with_deleted.count}"
