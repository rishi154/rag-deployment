# Private service connection for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  name          = "${var.instance_name}-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.vpc_network
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.vpc_network
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "google_sql_database_instance" "pg" {
  name             = var.instance_name
  database_version = "POSTGRES_15"
  region           = var.region
  depends_on       = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier              = "db-custom-2-3840"
    availability_type = "REGIONAL"
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.vpc_network
    }
    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
    }
    maintenance_window {
      day  = 7   # Sunday
      hour = 2   # 02:00 UTC
    }
    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = false
    }
  }
}

resource "google_sql_database" "db" {
  name     = var.db_name
  instance = google_sql_database_instance.pg.name
}

resource "google_sql_user" "user" {
  name     = var.db_user
  instance = google_sql_database_instance.pg.name
  password = var.db_password
}

output "private_ip"      { value = google_sql_database_instance.pg.private_ip_address }
output "connection_name" { value = google_sql_database_instance.pg.connection_name }
output "instance_id"     { value = google_sql_database_instance.pg.id }
