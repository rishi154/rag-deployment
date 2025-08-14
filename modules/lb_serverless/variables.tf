variable "project_id" { type = string }
variable "region" { type = string }
variable "domain_name" { type = string }
variable "security_policy" { type = string } # Cloud Armor policy id
variable "frontend_run_service" { type = string }
variable "backend_run_service" { type = string }
variable "enable_iap" {
  type = bool
  default = false
}
variable "iap_client_id" {
  type = string
  default = ""
}
variable "iap_client_secret" {
  type = string
  default = ""
}
