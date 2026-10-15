# pest_api

Ruby on Rails 8 API for Pest onboarding. Same shape as Proposalist: Devise JWT, dry-validation contracts, Build/Save services, and response normalizers.

Ruby 3.3.3. PostgreSQL.

## Local development with Docker

Prerequisites: Docker Desktop.

```bash
docker compose -f docker-compose.dev.yml up -d
```

The API is at `http://localhost:3000`. On boot it creates the database and seeds a dev login:

* Email: `admin@example.com`
* Password: value of `DEV_DEFAULT_PASSWORD` (defaults to `pass123!!!`)
* Role: admin

Recruiters `jordan.lee@example.com` and `alex.nguyen@example.com` use the same password. Every seeded rep also has a login with that password. A rep only sees people they recruited. Morgan Hale (`morgan.hale@example.com`) recruited Casey Nguyen.

Password reset emails are written to `tmp/mail`. Admins can also set a password from Users.

Postgres is published on port **5434**:

```
postgres://postgres:postgres@localhost:5434/pest_api_development
```

Creating a rep sends each selected onboarding document by email. In development those messages are written to `tmp/mail`.

## Native setup

1. `rbenv install 3.3.3` if needed, then `rbenv local 3.3.3`
2. `bundle install`
3. Copy `.env.example` to `.env`
4. `bin/rails db:prepare db:seed`
5. `bin/rails s`

## Testing

```bash
bundle exec rspec
```

Background jobs use the async adapter in development, so document emails send in the web process. Production uses Solid Queue.
