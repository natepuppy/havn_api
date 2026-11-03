#!/usr/bin/env bash
# Hard-delete the seeded example.com users and reps from production.
# Usage: script/delete_seeded_people.sh production
set -euo pipefail

environment="${1:-}"
if [[ "$environment" != "production" ]]; then
  echo "Usage: script/delete_seeded_people.sh production" >&2
  exit 1
fi

project="havn-api-production"
port="${PEST_API_DATABASE_PORT:-5475}"
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

if ! lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
  cloud-sql-proxy --gcloud-auth "${project}:us-central1:havn-sql" --port "$port" >/tmp/havn-sql-proxy-production.log 2>&1 &
  proxy_pid=$!
  trap 'kill "$proxy_pid"' EXIT
  ready=0
  for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
    if lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
      ready=1
      break
    fi
    sleep 0.25
  done
  if [[ "$ready" != "1" ]]; then
    echo "Cloud SQL proxy did not start. See /tmp/havn-sql-proxy-production.log" >&2
    exit 1
  fi
fi

export PEST_API_DATABASE_PASSWORD
PEST_API_DATABASE_PASSWORD="$(gcloud secrets versions access latest --secret=PEST_API_DATABASE_PASSWORD --project="$project")"
export PEST_API_DATABASE_USERNAME="postgres"
export PEST_API_DATABASE_HOST="127.0.0.1"
export PEST_API_DATABASE_PORT="$port"
export RAILS_ENV="production"
export DISABLE_SPRING="1"
export RBENV_VERSION="${RBENV_VERSION:-3.3.3}"
export CONFIRM_DELETE_SEEDED_PEOPLE="production"

echo "Deleting seeded people in production"
bundle exec rails runner script/delete_seeded_people.rb
