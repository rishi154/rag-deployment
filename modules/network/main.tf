resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  private_ip_google_access = true
}

resource "google_compute_router" "router" {
  name    = "${var.vpc_name}-router"
  region  = var.region
  network = google_compute_network.vpc.name
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.vpc_name}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_vpc_access_connector" "serverless" {
  name          = var.vpc_connector_name
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = var.vpc_connector_cidr
  min_throughput = 200
  max_throughput = 300
}

# Optional restrictive egress firewall (allowlist). If none provided, allow all egress.
# NOTE: Serverless egress uses the connector -> subnet -> NAT. Firewall rules apply here.
resource "google_compute_firewall" "egress_allowlist" {
  count         = length(var.allowed_egress_cidrs) > 0 ? 1 : 0
  name          = "${var.vpc_name}-egress-allowlist"
  network       = google_compute_network.vpc.name
  direction     = "EGRESS"
  priority      = 1000
  destination_ranges = var.allowed_egress_cidrs
  allow {
    protocol = "tcp"
    ports    = ["80","443"]
  }
}

resource "google_compute_firewall" "egress_deny_all" {
  count     = length(var.allowed_egress_cidrs) > 0 ? 1 : 0
  name      = "${var.vpc_name}-egress-deny-all"
  network   = google_compute_network.vpc.name
  direction = "EGRESS"
  priority  = 65534
  deny {
    protocol = "all"
  }
}

output "vpc_id" { value = google_compute_network.vpc.id }
output "subnet_id" { value = google_compute_subnetwork.subnet.id }
output "vpc_connector_id" { value = google_vpc_access_connector.serverless.id }
output "vpc_connector_name" { value = google_vpc_access_connector.serverless.name }
