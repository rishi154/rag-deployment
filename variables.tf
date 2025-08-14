variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "Primary region for Cloud Run and VPC (e.g., us-central1)"
  default     = "us-central1"
}

variable "domain_name" {
  type        = string
  description = "Domain for HTTPS LB (e.g., app.example.com)"
}

variable "frontend_image" {
  type        = string
  description = "Container image for rag-frontend (Artifact Registry URL)"
  default     = "us-docker.pkg.dev/PROJECT/REPO/rag-frontend:latest"
}

variable "backend_image" {
  type        = string
  description = "Container image for rag-backend (Artifact Registry URL)"
  default     = "us-docker.pkg.dev/PROJECT/REPO/rag-backend:latest"
}

variable "min_instances" {
  type        = number
  description = "Minimum instances for Cloud Run services"
  default     = 0
}

variable "max_instances" {
  type        = number
  description = "Max instances for Cloud Run services"
  default     = 50
}

variable "allowed_egress_cidrs" {
  type        = list(string)
  description = "Egress allowlist (CIDRs or IPs) for outbound firewall from serverless VPC connector; empty = allow all"
  default     = []
}

variable "db_instance_name" {
  type        = string
  description = "Cloud SQL PostgreSQL instance name"
  default     = "rag-pgvector"
}

variable "db_name" {
  type        = string
  description = "Database name"
  default     = "ragdb"
}

variable "db_user" {
  type        = string
  description = "Database user"
  default     = "raguser"
}

variable "enable_iap" {
  type        = bool
  description = "Enable IAP protection for BOTH frontend and backend behind the HTTPS LB"
  default     = false
}

variable "iap_client_id" {
  type        = string
  description = "IAP OAuth2 Client ID"
  default     = ""
}

variable "iap_client_secret" {
  type        = string
  description = "IAP OAuth2 Client Secret"
  default     = ""
  sensitive   = true
}

variable "iap_members" {
  type        = list(string)
  description = "Principals allowed to access via IAP (e.g., user:alice@example.com, group:team@example.com, serviceAccount:svc@proj.iam.gserviceaccount.com)"
  default     = []
}
