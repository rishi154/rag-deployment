# Example: log-based metric for 5xx from Cloud Run
resource "google_logging_metric" "cloudrun_5xx" {
  name   = "cloudrun_5xx_count"
  filter = "resource.type=\"cloud_run_revision\" severity>=ERROR"
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

# Example alert policy (tune thresholds)
resource "google_monitoring_alert_policy" "run_errors" {
  display_name = "Cloud Run elevated errors"
  combiner     = "OR"
  conditions {
    display_name = "5xx spike"
    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND metric.type=\"logging.googleapis.com/user/${google_logging_metric.cloudrun_5xx.name}\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 10
      trigger { count = 1 }
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_DELTA"
      }
    }
  }
  notification_channels = []
}
