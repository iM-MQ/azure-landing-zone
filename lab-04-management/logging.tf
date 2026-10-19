data "azurerm_subscription" "current" {}

resource "azurerm_resource_group" "management" {
  name     = "rg-${var.prefix}-management-${var.location_short}"
  location = var.location

  tags = {
    "cost-centre" = "platform"
  }
}

# The landing zone's central log store
resource "azurerm_log_analytics_workspace" "platform" {
  name                = "law-${var.prefix}-platform-${var.location_short}"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  daily_quota_gb      = var.daily_quota_gb
}

# Send every subscription-level event to the workspace: creates, deletes,
# role changes, policy denials and service health
resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  name                       = "send-activity-log-to-law"
  target_resource_id         = data.azurerm_subscription.current.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.platform.id

  dynamic "enabled_log" {
    for_each = toset(var.activity_log_categories)

    content {
      category = enabled_log.value
    }
  }
}