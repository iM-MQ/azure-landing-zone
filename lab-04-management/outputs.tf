output "workspace_name" {
  description = "Central Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.platform.name
}

output "workspace_customer_id" {
  description = "Workspace ID used when querying logs from the CLI"
  value       = azurerm_log_analytics_workspace.platform.workspace_id
}

output "budget_name" {
  description = "Monthly subscription budget"
  value       = azurerm_consumption_budget_subscription.monthly.name
}

output "reader_group" {
  description = "Entra ID group with read-only access across the landing zone"
  value       = azuread_group.platform_readers.display_name
}

output "reader_role_scope" {
  description = "Where the Reader role is assigned"
  value       = azurerm_role_assignment.platform_readers.scope
}