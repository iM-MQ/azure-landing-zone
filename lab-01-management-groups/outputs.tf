output "org_management_group" {
  value = azurerm_management_group.org.name
}

output "level1_management_groups" {
  value = { for k, mg in azurerm_management_group.level1 : k => mg.name }
}

output "level2_management_groups" {
  value = { for k, mg in azurerm_management_group.level2 : k => mg.name }
}

output "subscription_placed_in" {
  value = azurerm_management_group.level2[var.subscription_placement].name
}