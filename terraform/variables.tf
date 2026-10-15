variable "project_id" {
  type        = string
  description = "GCP project that already exists, e.g. havn-api-staging."
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "service_name" {
  type    = string
  default = "havn-api"
}

variable "worker_service_name" {
  type    = string
  default = "havn-worker"
}

variable "image" {
  type        = string
  description = "Bootstrap image. Later deploys replace it; Terraform ignores image changes."
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "frontend_url" {
  type        = string
  description = "Public origin of the web app, no trailing path. Used in password-reset links."
}

variable "api_domain" {
  type        = string
  description = "Public hostname for this API, without a scheme."
}

variable "rails_master_key_file" {
  type        = string
  description = "Path to config/master.key. That key decrypts config/credentials.yml.enc."
  default     = "../config/master.key"
}

variable "cpu" {
  type    = string
  default = "1"
}

variable "memory" {
  type    = string
  default = "1Gi"
}

variable "min_instances" {
  type    = number
  default = 0
}

variable "max_instances" {
  type    = number
  default = 2
}

variable "rails_max_threads" {
  type    = string
  default = "5"
}

variable "solid_queue_in_web" {
  type        = bool
  description = "Run Solid Queue inside the web process. Use this when there is no worker service."
  default     = true
}

variable "create_worker" {
  type        = bool
  description = "Private Cloud Run service that owns Solid Queue. Leave false on staging."
  default     = false
}

variable "worker_cpu" {
  type    = string
  default = "1"
}

variable "worker_memory" {
  type    = string
  default = "1Gi"
}

variable "worker_min_instances" {
  type    = number
  default = 1
}

variable "db_instance_name" {
  type    = string
  default = "havn-sql"
}

variable "db_version" {
  type    = string
  default = "POSTGRES_17"
}

variable "db_tier" {
  type    = string
  default = "db-f1-micro"
}

variable "db_disk_size" {
  type    = number
  default = 10
}

variable "db_availability_type" {
  type    = string
  default = "ZONAL"
}

variable "db_max_connections" {
  type    = number
  default = 50
}

variable "db_deletion_protection" {
  type    = bool
  default = true
}

variable "db_backup_enabled" {
  type    = bool
  default = true
}

variable "db_pitr_enabled" {
  type    = bool
  default = false
}

variable "db_backup_retention_days" {
  type    = number
  default = 7
}

variable "db_name" {
  type        = string
  description = "Primary database. Cache, queue, and cable databases use this name plus a suffix."
  default     = "pest_api_production"
}
