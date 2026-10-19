data "azurerm_management_group" "org" {
  name = "mg-${var.prefix}"
}

# Access is granted to groups, not individual people
resource "azuread_group" "platform_readers" {
  display_name            = var.reader_group_name
  description             = "Read-only access to everything in the landing zone"
  security_enabled        = true
  prevent_duplicate_names = true
}

# Assigned once at the top of the hierarchy, inherited by every subscription below
resource "azurerm_role_assignment" "platform_readers" {
  scope                = data.azurerm_management_group.org.id
  role_definition_name = "Reader"
  principal_id         = azuread_group.platform_readers.object_id

  # A new group can take a minute to reach every part of Azure.
  # Declaring the type stops Azure rejecting the assignment in that gap
  principal_type = "Group"
}