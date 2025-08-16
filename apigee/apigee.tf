# Apigee X organization and environment setup
# Note: Apigee requires specific billing and org setup

# Enable Apigee API
resource "google_project_service" "apigee_services" {
  for_each = toset([
    "apigee.googleapis.com",
    "apigeeconnect.googleapis.com",
    "compute.googleapis.com"
  ])
  project = var.project_id
  service = each.key
  disable_on_destroy = true
}

# Apigee Organization (requires billing account)
resource "google_apigee_organization" "org" {
  project_id                           = var.project_id
  analytics_region                     = var.region
  runtime_type                         = "CLOUD"
  billing_type                         = "PAYG"
  authorized_network                   = var.vpc_network
  runtime_database_encryption_key_name = null
  
  depends_on = [google_project_service.apigee_services]
}

# Apigee Environment
resource "google_apigee_environment" "ai_env" {
  org_id       = google_apigee_organization.org.id
  name         = "ai-env"
  description  = "AI Gateway Environment"
  display_name = "AI Environment"
}

# Environment Group for hostname routing
resource "google_apigee_envgroup" "ai_envgroup" {
  org_id    = google_apigee_organization.org.id
  name      = "ai-env-group"
  hostnames = [var.ai_gateway_hostname]
}

# Attach environment to group
resource "google_apigee_envgroup_attachment" "ai_env_attach" {
  envgroup_id = google_apigee_envgroup.ai_envgroup.id
  environment = google_apigee_environment.ai_env.name
}

# Apigee Instance (required for runtime)
resource "google_apigee_instance" "ai_instance" {
  org_id                    = google_apigee_organization.org.id
  name                      = "ai-instance"
  location                  = var.region
  description               = "AI Gateway Instance"
  display_name              = "AI Instance"
  disk_encryption_key_name  = null
  
  depends_on = [google_apigee_environment.ai_env]
}

# Attach instance to environment
resource "google_apigee_instance_attachment" "ai_attachment" {
  instance_id = google_apigee_instance.ai_instance.id
  environment = google_apigee_environment.ai_env.name
}

