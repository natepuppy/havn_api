#!/usr/bin/env bash
# Create the four Havn GCP projects and attach a billing account.
# Usage: BILLING_ACCOUNT_ID=XXXXXX-XXXXXX-XXXXXX ./scripts/bootstrap-projects.sh
set -euo pipefail

if [[ -z "${BILLING_ACCOUNT_ID:-}" ]]; then
  echo "Set BILLING_ACCOUNT_ID. List accounts with: gcloud billing accounts list" >&2
  exit 1
fi

projects=(
  "havn-api-staging|Havn API staging"
  "havn-api-production|Havn API production"
  "havn-frontend-staging|Havn frontend staging"
  "havn-frontend-production|Havn frontend production"
)

for entry in "${projects[@]}"; do
  project_id="${entry%%|*}"
  name="${entry#*|}"

  if gcloud projects describe "$project_id" >/dev/null 2>&1; then
    echo "Project $project_id already exists."
  else
    gcloud projects create "$project_id" --name="$name"
  fi

  gcloud billing projects link "$project_id" --billing-account="$BILLING_ACCOUNT_ID"
done

echo "Projects are ready. Next: pest_api/terraform/apply.sh, then pest/terraform/apply.sh."
