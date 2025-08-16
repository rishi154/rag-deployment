# Output Apigee endpoint
output "apigee_endpoint" {
  description = "Apigee AI Gateway endpoint"
  value       = "https://${var.ai_gateway_hostname}"
}

output "apigee_org_id" {
  description = "Apigee Organization ID"
  value       = google_apigee_organization.org.id
}

output "apigee_environment" {
  description = "Apigee Environment name"
  value       = google_apigee_environment.ai_env.name
}