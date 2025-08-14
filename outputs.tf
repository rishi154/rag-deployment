output "lb_ip_address" {
  description = "Global external IP of the HTTPS load balancer"
  value       = module.lb.ip_address
}

output "frontend_url" {
  value       = "https://${var.domain_name}"
}

output "backend_url" {
  value       = "https://${var.domain_name}/api"
}

output "db_private_ip" {
  description = "Cloud SQL private IP"
  value       = module.pgvector_db.private_ip
}

output "db_connection_name" {
  description = "Cloud SQL connection name (for Unix socket/proxy if preferred)"
  value       = module.pgvector_db.connection_name
}

output "artifact_registry_repo" {
  description = "Artifact Registry repository URL for container images"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/rag-repo"
}
