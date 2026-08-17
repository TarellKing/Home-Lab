# =============================================================================
# THE PERSISTENT LOGGING PIPELINE
# =============================================================================
# This file is the answer to "when I destroy everything, logging still works
# next time". Every log group the honeynet writes to is created HERE, in the
# layer you rarely destroy -- derived from the catalog, not from the running
# instances. Consequences:
#
#   * `make destroy-honeynet` deletes the EC2 box. Log groups, history, and any
#     dashboards or saved queries pointed at them are untouched.
#   * A service toggled `enabled: false` keeps its group.
#   * The next deployment writes into the exact same group names, so a Logs
#     Insights query you wrote months ago still works.
# =============================================================================

resource "aws_cloudwatch_log_group" "honeynet" {
  for_each = module.catalog.log_groups

  name              = each.value.path
  retention_in_days = var.log_retention_days

  tags = {
    Kind       = each.value.kind
    Source     = each.value.service
    Stream     = each.value.stream
    LogFormat  = each.value.format
    CatalogKey = each.key
  }
}
