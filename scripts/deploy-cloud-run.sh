#!/usr/bin/env bash
# Build this repo and roll it onto the Cloud Run services Terraform created.
# Usage: ./scripts/deploy-cloud-run.sh staging|production
set -euo pipefail

env_name="${1:?usage: ./scripts/deploy-cloud-run.sh staging|production}"
project_id="havn-api-${env_name}"
region="us-central1"
root="$(cd "$(dirname "$0")/.." && pwd)"

deploy_one() {
  local service="$1"
  if ! gcloud run services describe "$service" --project="$project_id" --region="$region" >/dev/null 2>&1; then
    return 0
  fi
  gcloud run deploy "$service" \
    --source="$root" \
    --project="$project_id" \
    --region="$region" \
    --args="./bin/rails,server" \
    --quiet
}

deploy_one havn-api
deploy_one havn-worker
