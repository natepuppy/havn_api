source "https://rubygems.org"

ruby "3.3.3"

gem "rails", "~> 8.0.4"
# json 3.0 dropped the quirks_mode keyword Rails 8.0 still passes.
gem "json", "~> 3.1"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false

gem "rack-cors"
gem "devise"
gem "devise-jwt"
gem "cancancan"
gem "dry-validation"
gem "acts_as_paranoid"
gem "activerecord-import"
gem "valid_email2"
gem "mailgun-ruby"
gem "mission_control-jobs"
gem "propshaft"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "dotenv-rails"
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
end
