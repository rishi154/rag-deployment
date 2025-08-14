# Enable APIs
module "apis" {
  source = "./apis"
}

# Network
module "network" {
  source              = "./modules/network"
  project_id          = var.project_id
  region              = var.region
  allowed_egress_cidrs = var.allowed_egress_cidrs
}

# Cloud Armor
module "armor" {
  source = "./modules/cloud_armor"
  name   = "rag-waf"
}

# Artifact Registry for container images
resource "google_artifact_registry_repository" "repo" {
  repository_id = "rag-repo"
  format        = "DOCKER"
  location      = var.region
}

# Cloud Run services
module "run_frontend" {
  source        = "./modules/cloudrun_service"
  name          = "rag-frontend"
  image         = var.frontend_image
  region        = var.region
  project_id    = var.project_id
  vpc_connector = module.network.vpc_connector_name
  ingress       = "INGRESS_TRAFFIC_ALL"
  env = {
    REACT_APP_API_BASE = "/api"
  }
}

# Cloud Run IAM for Load Balancer access
resource "google_cloud_run_service_iam_member" "frontend_invoker" {
  service  = module.run_frontend.service_name
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_service_iam_member" "backend_invoker" {
  service  = module.run_backend.service_name
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Get project data for IAP service account
data "google_project" "current" {}

# HTTPS LB + path routing
module "lb" {
  source               = "./modules/lb_serverless"
  project_id           = var.project_id
  region               = var.region
  domain_name          = var.domain_name
  security_policy      = module.armor.policy_id
  frontend_run_service = module.run_frontend.service_name
  backend_run_service  = module.run_backend.service_name
  enable_iap           = var.enable_iap
  iap_client_id        = var.iap_client_id
  iap_client_secret    = var.iap_client_secret
  depends_on          = [google_cloud_run_service_iam_member.frontend_invoker, google_cloud_run_service_iam_member.backend_invoker]
}

# Observability (logging metrics + alert policy examples)
module "observability" {
  source     = "./modules/observability"
  project_id = var.project_id
}

# Optional Secrets bootstrap
module "secrets" {
  source     = "./modules/secrets"
  project_id = var.project_id
  secrets    = {
    # "VERTEX_API_KEY"    = ""
    # "RERANKER_API_KEY"  = ""
    # "MODEL_ARMOR_KEY"   = ""
  }
}

# -----------------------------------------------------------------------------
# Cloud SQL PostgreSQL + pgvector (private IP)
# -----------------------------------------------------------------------------
resource "random_password" "db" {
  length  = 24
  special = true
}

module "pgvector_db" {
  source        = "./modules/cloudsql_pgvector"
  project_id    = var.project_id
  region        = var.region
  instance_name = var.db_instance_name
  db_name       = var.db_name
  db_user       = var.db_user
  db_password   = random_password.db.result
  vpc_network   = module.network.vpc_id
}

# Allow backend service account to access Cloud SQL (optional but useful)
resource "google_project_iam_member" "backend_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${module.run_backend.service_sa_email}"
}

# DB secrets bootstrap
module "db_secrets" {
  source     = "./modules/secrets"
  project_id = var.project_id
  secrets = {
    DB_HOST     = module.pgvector_db.private_ip
    DB_NAME     = var.db_name
    DB_USER     = var.db_user
    DB_PASSWORD = random_password.db.result
  }
}

# Backend with DB secrets
module "run_backend" {
  source        = "./modules/cloudrun_service"
  name          = "rag-backend"
  image         = var.backend_image
  region        = var.region
  project_id    = var.project_id
  vpc_connector = module.network.vpc_connector_name
  egress        = "ALL_TRAFFIC"
  env = {
    ENABLE_INTERNET = "true"
  }
  secrets = {
    DB_HOST     = "DB_HOST"
    DB_NAME     = "DB_NAME"
    DB_USER     = "DB_USER"
    DB_PASSWORD = "DB_PASSWORD"
  }
  depends_on = [module.db_secrets]
}

# -----------------------------------------------------------------------------
# IAP protection for BOTH frontend and backend (at HTTPS LB backend services)
# -----------------------------------------------------------------------------
locals {
  iap_enabled = var.enable_iap && length(var.iap_client_id) > 0 && length(var.iap_client_secret) > 0
}

# IAP IAM bindings - grant users access to IAP-protected resources
resource "google_iap_web_backend_service_iam_binding" "fe_allow" {
  count = local.iap_enabled ? 1 : 0
  web_backend_service = module.lb.be_frontend_name
  role = "roles/iap.httpsResourceAccessor"
  members = var.iap_members
}

resource "google_iap_web_backend_service_iam_binding" "be_allow" {
  count = local.iap_enabled ? 1 : 0
  web_backend_service = module.lb.be_backend_name
  role = "roles/iap.httpsResourceAccessor"
  members = var.iap_members
}
