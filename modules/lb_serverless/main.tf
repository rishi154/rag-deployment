# Reserve global IP
resource "google_compute_global_address" "lb_ip" {
  name = "rag-global-ip"
}

# Managed SSL cert for domain
resource "google_compute_managed_ssl_certificate" "managed" {
  name = "rag-managed-cert"
  managed {
    domains = [var.domain_name]
  }
}

# Serverless NEGs for the two Cloud Run services
resource "google_compute_region_network_endpoint_group" "neg_frontend" {
  name                  = "neg-rag-frontend"
  region                = var.region
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = var.frontend_run_service
  }
}

resource "google_compute_region_network_endpoint_group" "neg_backend" {
  name                  = "neg-rag-backend"
  region                = var.region
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = var.backend_run_service
  }
}

resource "google_compute_backend_service" "be_frontend" {
  name                            = "be-rag-frontend"
  load_balancing_scheme           = "EXTERNAL_MANAGED"
  protocol                        = "HTTP"
  security_policy                 = var.security_policy
  backend {
    group = google_compute_region_network_endpoint_group.neg_frontend.id
  }
  
  dynamic "iap" {
    for_each = var.enable_iap && var.iap_client_id != "" && var.iap_client_secret != "" ? [1] : []
    content {
      oauth2_client_id     = var.iap_client_id
      oauth2_client_secret = var.iap_client_secret
    }
  }
}

resource "google_compute_backend_service" "be_backend" {
  name                            = "be-rag-backend"
  load_balancing_scheme           = "EXTERNAL_MANAGED"
  protocol                        = "HTTP"
  security_policy                 = var.security_policy
  backend {
    group = google_compute_region_network_endpoint_group.neg_backend.id
  }
  
  dynamic "iap" {
    for_each = var.enable_iap && var.iap_client_id != "" && var.iap_client_secret != "" ? [1] : []
    content {
      oauth2_client_id     = var.iap_client_id
      oauth2_client_secret = var.iap_client_secret
    }
  }
}



resource "google_compute_url_map" "map" {
  name            = "rag-url-map"
  default_service = google_compute_backend_service.be_frontend.id

  host_rule {
    hosts        = [var.domain_name]
    path_matcher = "pm1"
  }

  path_matcher {
    name            = "pm1"
    default_service = google_compute_backend_service.be_frontend.id

    path_rule {
      paths   = ["/api/*"]
      service = google_compute_backend_service.be_backend.id
    }
  }
}

resource "google_compute_target_https_proxy" "https_proxy" {
  name             = "rag-https-proxy"
  ssl_certificates = [google_compute_managed_ssl_certificate.managed.id]
  url_map          = google_compute_url_map.map.id
}

resource "google_compute_global_forwarding_rule" "https_rule" {
  name                  = "rag-https-forwarding-rule"
  target                = google_compute_target_https_proxy.https_proxy.id
  port_range            = "443"
  ip_address            = google_compute_global_address.lb_ip.address
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

# HTTP to HTTPS redirect
resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "rag-http-proxy"
  url_map = google_compute_url_map.redirect_map.id
}

resource "google_compute_url_map" "redirect_map" {
  name = "rag-redirect-map"
  default_url_redirect {
    https_redirect = true
    strip_query    = false
  }
}

resource "google_compute_global_forwarding_rule" "http_rule" {
  name                  = "rag-http-forwarding-rule"
  target                = google_compute_target_http_proxy.http_proxy.id
  port_range            = "80"
  ip_address            = google_compute_global_address.lb_ip.address
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

output "ip_address" { value = google_compute_global_address.lb_ip.address }
