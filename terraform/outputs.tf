output "service_url" {
  description = "Public HTTPS URL of the API. Point the frontend VITE_PEST_API_URL and VITE_AUTH_API_URL here."
  value       = google_cloud_run_v2_service.web.uri
}

output "api_domain_status" {
  description = "Domain mapping status, including the DNS records Cloud Run wants."
  value       = google_cloud_run_domain_mapping.api.status
}

output "worker_service_url" {
  description = "Internal URL of the Solid Queue worker. Empty when create_worker is false."
  value       = one(google_cloud_run_v2_service.worker[*].uri)
}

output "cloudsql_connection_name" {
  value = google_sql_database_instance.main.connection_name
}

output "runtime_service_account" {
  value = google_service_account.runtime.email
}
