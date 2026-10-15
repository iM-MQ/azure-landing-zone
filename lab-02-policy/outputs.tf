output "assignments" {
  value = {
    allowed_locations    = "${azurerm_management_group_policy_assignment.allowed_locations.name} at ${data.azurerm_management_group.org.name}"
    allowed_rg_locations = "${azurerm_management_group_policy_assignment.allowed_rg_locations.name} at ${data.azurerm_management_group.org.name}"
    require_rg_tag       = "${azurerm_management_group_policy_assignment.require_rg_tag.name} at ${data.azurerm_management_group.landingzones.name}"
    corp_deny_types      = "${azurerm_management_group_policy_assignment.corp_deny_types.name} at ${data.azurerm_management_group.corp.name}"
  }
}