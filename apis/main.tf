locals {
  services = [
    "run.googleapis.com",
    "compute.googleapis.com",
    "vpcaccess.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "secretmanager.googleapis.com",
    "aiplatform.googleapis.com",
    "artifactregistry.googleapis.com",
    "iap.googleapis.com",
    "certificatemanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com"
  ]
}

resource "google_project_service" "required" {
  for_each           = toset(local.services)
  service            = each.key
  disable_on_destroy = false
}
