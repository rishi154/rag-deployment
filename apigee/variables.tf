variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "Primary region for Apigee"
}

variable "ai_gateway_hostname" {
  type        = string
  description = "Hostname for Apigee AI Gateway (e.g., api.nvrstech.com)"
}

variable "vpc_network" {
  type        = string
  description = "VPC network ID for Apigee"
}