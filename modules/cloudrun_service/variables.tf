variable "name" {
  type = string
}
variable "image" {
  type = string
}
variable "region" {
  type = string
}
variable "project_id" {
  type = string
}
variable "ingress" { 
  type = string
  default = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
}
variable "min_instances" {
  type = number
  default = 0
}
variable "max_instances" {
  type = number
  default = 50
}
variable "vpc_connector" {
  type = string
}
variable "egress" {
  type = string
  default = "ALL_TRAFFIC"
}
variable "env" {
  type = map(string)
  default = {}
}
variable "secrets" {
  description = "Map of { env_name = secret_id } to inject from Secret Manager latest version"
  type = map(string)
  default = {}
}
variable "port" {
  type = number
  default = 8080
}
