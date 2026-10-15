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
  local describe_err
  if ! describe_err="$(gcloud run services describe "$service" --project="$project_id" --region="$region" 2>&1 >/dev/null)"; then
    if [[ "$describe_err" == *"NOT_FOUND"* || "$describe_err" == *"Cannot find service"* ]]; then
      echo "Skipping ${service}; it is not in ${project_id}."
      return 0
    fi
    printf '%s\n' "$describe_err" >&2
    return 1
  fi
  echo "Deploying ${service} to ${project_id}."
  gcloud run deploy "$service" \
    --source="$root" \
    --project="$project_id" \
    --region="$region" \
    --args="./bin/rails,server" \
    --quiet
}

deploy_one havn-api
deploy_one havn-worker
