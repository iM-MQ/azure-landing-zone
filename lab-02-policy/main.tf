# Lab 01's management groups, read rather than rebuilt
data "azurerm_management_group" "org" {
  name = "mg-${var.prefix}"
}

data "azurerm_management_group" "landingzones" {
  name = "mg-${var.prefix}-landingzones"
}

data "azurerm_management_group" "corp" {
  name = "mg-${var.prefix}-corp"
}

# Built-in policy definitions, looked up by their permanent IDs
data "azurerm_policy_definition" "allowed_locations" {
  name = "e56962a6-4747-49cd-b67b-bf8b01975c4c"
}

data "azurerm_policy_definition" "allowed_rg_locations" {
  name = "e765b5de-1225-4ba3-bd56-1ac6695af988"
}

data "azurerm_policy_definition" "require_rg_tag" {
  name = "96670d01-0a4d-4649-9c89-2d3abc0a5025"
}

data "azurerm_policy_definition" "not_allowed_types" {
  name = "6c112d4e-5bc7-47ae-a041-ea2d9dccd749"
}

# 1. At the top: resources must be in an allowed region
resource "azurerm_management_group_policy_assignment" "allowed_locations" {
  name                 = "alz-allowed-locations"
  display_name         = "Allowed locations for resources"
  description          = "Resources may only be created in the approved regions."
  management_group_id  = data.azurerm_management_group.org.id
  policy_definition_id = data.azurerm_policy_definition.allowed_locations.id

  parameters = jsonencode({
    listOfAllowedLocations = { value = var.allowed_locations }
    effect                 = { value = "Deny" }
  })

  non_compliance_message {
    content = "Resources must be created in an approved region: ${join(", ", var.allowed_locations)}."
  }
}

# 2. At the top: resource groups must be in an allowed region
resource "azurerm_management_group_policy_assignment" "allowed_rg_locations" {
  name                 = "alz-allowed-rg-locations"
  display_name         = "Allowed locations for resource groups"
  description          = "Resource groups may only be created in the approved regions."
  management_group_id  = data.azurerm_management_group.org.id
  policy_definition_id = data.azurerm_policy_definition.allowed_rg_locations.id

  parameters = jsonencode({
    listOfAllowedLocations = { value = var.allowed_locations }
    effect                 = { value = "Deny" }
  })

  non_compliance_message {
    content = "Resource groups must be created in an approved region: ${join(", ", var.allowed_locations)}."
  }
}

# 3. At Landing Zones: resource groups must carry a cost-centre tag
resource "azurerm_management_group_policy_assignment" "require_rg_tag" {
  name                 = "lz-require-rg-tag"
  display_name         = "Require a ${var.required_tag} tag on resource groups"
  description          = "Every resource group in a landing zone must say which cost centre pays for it."
  management_group_id  = data.azurerm_management_group.landingzones.id
  policy_definition_id = data.azurerm_policy_definition.require_rg_tag.id

  parameters = jsonencode({
    tagName = { value = var.required_tag }
  })

  non_compliance_message {
    content = "Resource groups in a landing zone must have a '${var.required_tag}' tag."
  }
}

# 4. At Corp: no public IP addresses
resource "azurerm_management_group_policy_assignment" "corp_deny_types" {
  name                 = "corp-deny-public-ip"
  display_name         = "Deny public IP addresses in Corp"
  description          = "Corp landing zones are internal only and reach the internet through the hub."
  management_group_id  = data.azurerm_management_group.corp.id
  policy_definition_id = data.azurerm_policy_definition.not_allowed_types.id

  parameters = jsonencode({
    listOfResourceTypesNotAllowed = { value = var.corp_denied_resource_types }
    effect                        = { value = "Deny" }
  })

  non_compliance_message {
    content = "Public IP addresses are not allowed in Corp landing zones. Internet access goes through the hub network."
  }
}