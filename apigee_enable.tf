# Ensure Apigee and related APIs are enabled
resource "google_project_service" "apigee_services" {
  for_each = toset([
    "apigee.googleapis.com",
    "apigeeconnect.googleapis.com"
  ])
  project = var.project_id
  service = each.key
}
