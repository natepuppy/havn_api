terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Local state. It holds the database password and the JWT secret, so do not
  # commit terraform.tfstate. To move state into GCS later:
  #   gcloud storage buckets create gs://havn-tf-state --location=us-central1
  # then add a backend "gcs" block and run terraform init -migrate-state.
}

provider "google" {
  project = var.project_id
  region  = var.region
}
