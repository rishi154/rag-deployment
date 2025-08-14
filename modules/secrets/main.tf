resource "google_secret_manager_secret" "secrets" {
  for_each = var.secrets
  secret_id = each.key
  replication {
    auto {}
  }
}

# Optional initial versions (only if creating fresh)
resource "google_secret_manager_secret_version" "versions" {
  for_each    = var.secrets
  secret      = google_secret_manager_secret.secrets[each.key].id
  secret_data = each.value
  depends_on  = [google_secret_manager_secret.secrets]
}
