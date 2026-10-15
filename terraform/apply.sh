#!/usr/bin/env bash
# Apply one API environment: ./apply.sh staging|production
set -euo pipefail

env_name="${1:?usage: ./apply.sh staging|production}"
cd "$(dirname "$0")"

example="environments/${env_name}.tfvars.example"
tfvars="environments/${env_name}.tfvars"

if [[ ! -f "$tfvars" ]]; then
  cp "$example" "$tfvars"
  echo "Created $tfvars from the example."
fi

terraform init -input=false
if ! terraform workspace select "$env_name"; then
  terraform workspace new "$env_name"
fi

terraform apply -var-file="$tfvars"
