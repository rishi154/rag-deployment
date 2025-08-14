variable "project_id" { type = string }
variable "region" { type = string }
variable "vpc_name" {
  type = string
  default = "rag-vpc"
}
variable "subnet_cidr" {
  type = string
  default = "10.10.0.0/20"
}
variable "subnet_name" {
  type = string
  default = "rag-subnet"
}
variable "vpc_connector_name" {
  type = string
  default = "rag-serverless-conn"
}
variable "vpc_connector_cidr" {
  type = string
  default = "10.8.0.0/28"
}
variable "allowed_egress_cidrs" {
  type = list(string)
  default = []
}
