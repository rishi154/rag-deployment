resource "google_service_account" "sa" {
  account_id   = "${var.name}-sa"
  display_name = "SA for ${var.name}"
}

# Allow basic access to Secret Manager versions if secrets provided
resource "google_project_iam_member" "secrets_access" {
  for_each = var.secrets
  project  = var.project_id
  role     = "roles/secretmanager.secretAccessor"
  member   = "serviceAccount:${google_service_account.sa.email}"
}

resource "google_cloud_run_v2_service" "svc" {
  name     = var.name
  location = var.region
  ingress  = var.ingress

  template {
    service_account = google_service_account.sa.email

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    containers {
      image = var.image
      ports { container_port = var.port }

      dynamic "env" {
        for_each = var.env
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = var.secrets
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value
              version = "latest"
            }
          }
        }
      }
    }

    vpc_access {
      connector = "projects/${var.project_id}/locations/${var.region}/connectors/${var.vpc_connector}"
      egress    = var.egress
    }
  }
}

output "service_id" { value = google_cloud_run_v2_service.svc.id }
output "service_name" { value = google_cloud_run_v2_service.svc.name }
output "service_uri" { value = google_cloud_run_v2_service.svc.uri }
output "service_sa_email" { value = google_service_account.sa.email }
