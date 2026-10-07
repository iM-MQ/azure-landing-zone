# The subscription Terraform is signed in to
data "azurerm_subscription" "current" {}

# The hierarchy, written as data rather than repeated resource blocks
locals {
  # Level 1: directly under the organisation's management group
  level1 = {
    platform       = "Platform"
    landingzones   = "Landing Zones"
    sandbox        = "Sandbox"
    decommissioned = "Decommissioned"
  }

  # Level 2: each one names its parent from level 1
  level2 = {
    connectivity = { display_name = "Connectivity", parent = "platform" }
    identity     = { display_name = "Identity", parent = "platform" }
    management   = { display_name = "Management", parent = "platform" }
    corp         = { display_name = "Corp", parent = "landingzones" }
    online       = { display_name = "Online", parent = "landingzones" }
  }
}

# The organisation's own top-level management group, under the Tenant Root Group
resource "azurerm_management_group" "org" {
  name         = "mg-${var.prefix}"
  display_name = "Landing Zone (${var.prefix})"
}

# Level 1, one management group per entry in local.level1
resource "azurerm_management_group" "level1" {
  for_each = local.level1

  name                       = "mg-${var.prefix}-${each.key}"
  display_name               = each.value
  parent_management_group_id = azurerm_management_group.org.id
}

# Level 2, each placed under the level 1 group it names
resource "azurerm_management_group" "level2" {
  for_each = local.level2

  name                       = "mg-${var.prefix}-${each.key}"
  display_name               = each.value.display_name
  parent_management_group_id = azurerm_management_group.level1[each.value.parent].id
}

# Move the lab subscription into its management group
resource "azurerm_management_group_subscription_association" "lab" {
  management_group_id = azurerm_management_group.level2[var.subscription_placement].id
  subscription_id     = data.azurerm_subscription.current.id
}