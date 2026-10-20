# Havn API — one Cloud Run environment.
#
# Projects are created first (scripts/bootstrap-projects.sh). Then, from this
# directory:
#   cp environments/staging.tfvars.example environments/staging.tfvars
#   ./apply.sh staging
#   ./apply.sh production
#
# Both environments use RAILS_ENV=production. This app has no staging.rb.
# Staging and production are separate GCP projects, so their databases are separate.
# Terraform ignores the container image after the first apply. Ship the app with
# scripts/deploy-cloud-run.sh.

locals {
  services = [
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "sqladmin.googleapis.com",
    "secretmanager.googleapis.com",
    "iam.googleapis.com",
    "compute.googleapis.com",
  ]

  rails_master_key = trimspace(file(var.rails_master_key_file))
  sql_socket       = "/cloudsql/${google_sql_database_instance.main.connection_name}"

  databases = {
    app   = var.db_name
    cache = "${var.db_name}_cache"
    queue = "${var.db_name}_queue"
    cable = "${var.db_name}_cable"
  }

  docusign_secret_env = var.docusign_configured ? [
    "DOCUSIGN_INTEGRATION_KEY",
    "DOCUSIGN_USER_ID",
    "DOCUSIGN_ACCOUNT_ID",
    "DOCUSIGN_TEMPLATE_ID",
    "DOCUSIGN_RSA_PRIVATE_KEY",
  ] : []

  docusign_plain_env = var.docusign_configured ? {
    DOCUSIGN_OAUTH_HOST = "https://account.docusign.com"
    DOCUSIGN_REST_HOST  = "https://na2.docusign.net"
  } : {}
}

resource "google_project_service" "services" {
  for_each           = toset(local.services)
  service            = each.value
  disable_on_destroy = false
}

resource "random_password" "db" {
  length  = 32
  special = false
}

resource "random_password" "devise_jwt" {
  length  = 64
  special = false
}

resource "google_sql_database_instance" "main" {
  name                = var.db_instance_name
  database_version    = var.db_version
  region              = var.region
  deletion_protection = var.db_deletion_protection

  settings {
    tier              = var.db_tier
    edition           = "ENTERPRISE"
    availability_type = var.db_availability_type
    disk_size         = var.db_disk_size
    disk_type         = "PD_SSD"
    disk_autoresize   = true

    database_flags {
      name  = "max_connections"
      value = tostring(var.db_max_connections)
    }

    insights_config {
      query_insights_enabled = true
      query_plans_per_minute = 5
      query_string_length    = 1024
    }

    backup_configuration {
      enabled                        = var.db_backup_enabled
      point_in_time_recovery_enabled = var.db_pitr_enabled
      start_time                     = "07:00"
      transaction_log_retention_days = var.db_pitr_enabled ? var.db_backup_retention_days : null

      backup_retention_settings {
        retained_backups = var.db_backup_retention_days
        retention_unit   = "COUNT"
      }
    }

    ip_configuration {
      ipv4_enabled = true
    }
  }

  lifecycle {
    ignore_changes = [settings[0].disk_size]
  }

  depends_on = [google_project_service.services]
}

resource "google_sql_database" "app" {
  for_each = local.databases
  name     = each.value
  instance = google_sql_database_instance.main.name
}

# The built-in postgres user can create tables. A brand-new role cannot, on PostgreSQL 15+.
resource "google_sql_user" "app" {
  name     = "postgres"
  instance = google_sql_database_instance.main.name
  password = random_password.db.result
}

resource "google_secret_manager_secret" "rails_master_key" {
  secret_id = "RAILS_MASTER_KEY"
  replication {
    auto {}
  }
  depends_on = [google_project_service.services]
}

resource "google_secret_manager_secret_version" "rails_master_key" {
  secret      = google_secret_manager_secret.rails_master_key.id
  secret_data = local.rails_master_key
}

resource "google_secret_manager_secret" "db_password" {
  secret_id = "PEST_API_DATABASE_PASSWORD"
  replication {
    auto {}
  }
  depends_on = [google_project_service.services]
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db.result
}

resource "google_secret_manager_secret" "devise_jwt" {
  secret_id = "DEVISE_JWT_SECRET_KEY"
  replication {
    auto {}
  }
  depends_on = [google_project_service.services]
}

resource "google_secret_manager_secret_version" "devise_jwt" {
  secret      = google_secret_manager_secret.devise_jwt.id
  secret_data = random_password.devise_jwt.result

  lifecycle {
    ignore_changes = [secret_data]
  }
}

# New projects no longer get a default Compute Engine service account.
resource "google_service_account" "runtime" {
  account_id   = "havn-runtime"
  display_name = "Havn API runtime"
  depends_on   = [google_project_service.services]
}

resource "google_project_iam_member" "cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.runtime.email}"
}

resource "google_project_iam_member" "secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.runtime.email}"
}

resource "google_cloud_run_v2_service" "web" {
  name                = var.service_name
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false

  lifecycle {
    precondition {
      condition     = !(var.solid_queue_in_web && var.create_worker)
      error_message = "Run Solid Queue in the web process or the worker, not both."
    }

    ignore_changes = [
      template[0].containers[0].image,
      template[0].containers[0].args,
      build_config,
      scaling,
      client,
      client_version,
    ]
  }

  template {
    service_account = google_service_account.runtime.email

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.main.connection_name]
      }
    }

    containers {
      image = var.image

      ports {
        container_port = 8080
      }

      resources {
        cpu_idle          = true
        startup_cpu_boost = true
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
      }

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }

      env {
        name  = "RAILS_ENV"
        value = "production"
      }
      env {
        name  = "SOLID_QUEUE_IN_PUMA"
        value = var.solid_queue_in_web ? "1" : "0"
      }
      env {
        name  = "RAILS_MAX_THREADS"
        value = var.rails_max_threads
      }
      env {
        name  = "INSTANCE_UNIX_SOCKET"
        value = local.sql_socket
      }
      env {
        name  = "PEST_API_DATABASE_USERNAME"
        value = "postgres"
      }
      env {
        name  = "FRONTEND_URL"
        value = var.frontend_url
      }
      env {
        name = "RAILS_MASTER_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.rails_master_key.secret_id
            version = "latest"
          }
        }
      }
      env {
        name = "PEST_API_DATABASE_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_password.secret_id
            version = "latest"
          }
        }
      }
      env {
        name = "DEVISE_JWT_SECRET_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.devise_jwt.secret_id
            version = "latest"
          }
        }
      }

      dynamic "env" {
        for_each = local.docusign_secret_env
        content {
          name = env.value
          value_source {
            secret_key_ref {
              secret  = env.value
              version = "latest"
            }
          }
        }
      }

      dynamic "env" {
        for_each = local.docusign_plain_env
        content {
          name  = env.key
          value = env.value
        }
      }
    }
  }

  depends_on = [
    google_project_iam_member.secret_accessor,
    google_project_iam_member.cloudsql_client,
    google_secret_manager_secret_version.rails_master_key,
    google_secret_manager_secret_version.db_password,
    google_secret_manager_secret_version.devise_jwt,
    google_sql_database.app,
    google_sql_user.app,
  ]
}

resource "google_cloud_run_v2_service" "worker" {
  count               = var.create_worker ? 1 : 0
  name                = var.worker_service_name
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  deletion_protection = false

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
      template[0].containers[0].args,
      build_config,
      scaling,
      client,
      client_version,
    ]
  }

  template {
    service_account = google_service_account.runtime.email

    scaling {
      min_instance_count = var.worker_min_instances
      max_instance_count = 1
    }

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.main.connection_name]
      }
    }

    containers {
      image = var.image

      ports {
        container_port = 8080
      }

      resources {
        cpu_idle          = false
        startup_cpu_boost = true
        limits = {
          cpu    = var.worker_cpu
          memory = var.worker_memory
        }
      }

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }

      env {
        name  = "RAILS_ENV"
        value = "production"
      }
      env {
        name  = "SOLID_QUEUE_IN_PUMA"
        value = "1"
      }
      env {
        name  = "RAILS_MAX_THREADS"
        value = "3"
      }
      env {
        name  = "INSTANCE_UNIX_SOCKET"
        value = local.sql_socket
      }
      env {
        name  = "PEST_API_DATABASE_USERNAME"
        value = "postgres"
      }
      env {
        name  = "FRONTEND_URL"
        value = var.frontend_url
      }
      env {
        name = "RAILS_MASTER_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.rails_master_key.secret_id
            version = "latest"
          }
        }
      }
      env {
        name = "PEST_API_DATABASE_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_password.secret_id
            version = "latest"
          }
        }
      }
      env {
        name = "DEVISE_JWT_SECRET_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.devise_jwt.secret_id
            version = "latest"
          }
        }
      }

      dynamic "env" {
        for_each = local.docusign_secret_env
        content {
          name = env.value
          value_source {
            secret_key_ref {
              secret  = env.value
              version = "latest"
            }
          }
        }
      }

      dynamic "env" {
        for_each = local.docusign_plain_env
        content {
          name  = env.key
          value = env.value
        }
      }
    }
  }

  depends_on = [
    google_project_iam_member.secret_accessor,
    google_project_iam_member.cloudsql_client,
    google_secret_manager_secret_version.rails_master_key,
    google_secret_manager_secret_version.db_password,
    google_secret_manager_secret_version.devise_jwt,
    google_sql_database.app,
    google_sql_user.app,
  ]
}

resource "google_cloud_run_v2_service_iam_member" "invoker" {
  name     = google_cloud_run_v2_service.web.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Cloud Run rejects this until havnpestcontrol.com is verified on the Google account.
resource "google_cloud_run_domain_mapping" "api" {
  location = var.region
  name     = var.api_domain
  project  = var.project_id

  metadata {
    namespace = var.project_id
  }

  spec {
    route_name       = google_cloud_run_v2_service.web.name
    certificate_mode = "AUTOMATIC"
  }
}
