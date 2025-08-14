
# ================================================
# Cloud DNS zone for chatbot domain
# ================================================

resource "google_dns_managed_zone" "chatbot_zone" {
  name        = "chatbot-zone"
  dns_name    = "${var.domain_name}."
  description = "Managed DNS zone for chatbot"
  
  dnssec_config {
    state = "off"
  }
}

# A record for root domain (both frontend and API)
resource "google_dns_record_set" "root_a_record" {
  name         = "${var.domain_name}."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.chatbot_zone.name
  rrdatas      = [module.lb.ip_address]
}

output "dns_name_servers" {
  description = "Name servers to set in Google Domains"
  value       = google_dns_managed_zone.chatbot_zone.name_servers
}
