# Root seed file, run by `bin/rails db:seed` and on database creation by
# `bin/rails db:prepare` / `db:setup`. Keep this idempotent.
if Rails.env.development? && ENV["DEV_DEFAULT_PASSWORD"].present?
  load Rails.root.join("db/seeds/development_seeds.rb")
end
