variable "project_id" { type = string }
variable "secrets" {
  description = "Map of secret_id => initial value (optional). Values are ignored if already exist."
  type = map(string)
  default = {}
}
