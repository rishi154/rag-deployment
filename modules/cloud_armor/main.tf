# Basic WAF with OWASP and some anti-abuse patterns; tune per your needs.
resource "google_compute_security_policy" "waf" {
  name = var.name

  rule {
    priority = 1000
    match {
      versioned_expr = "SRC_IPS_V1"
      config { src_ip_ranges = ["*"] }
    }
    action = "allow"
    preview = false
  }

  rule {
    action   = "deny(403)"
    priority = 2000
    match {
      expr { expression = "evaluatePreconfiguredWaf('xss-stable')" }
    }
    description = "Block XSS"
  }

  rule {
    action   = "deny(403)"
    priority = 2001
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('sqli-stable')"
      }
    }
    description = "Block SQLi"
  }

  rule {
    action   = "deny(403)"
    priority = 2002
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('lfi-stable')"
      }
    }
    description = "Block RFI/LFI"
  }

  rule {
    action   = "deny(403)"
    priority = 2100
    match {
      expr {
        expression = "request.headers['User-Agent'].matches('^$')"
      }
    }
    description = "Deny empty UA (basic bot)"
  }

  # Required default rule
  rule {
    action   = "allow"
    priority = 2147483647
    match {
      versioned_expr = "SRC_IPS_V1"
      config { src_ip_ranges = ["*"] }
    }
    description = "Default allow rule"
  }
}

output "policy_id" { value = google_compute_security_policy.waf.id }
