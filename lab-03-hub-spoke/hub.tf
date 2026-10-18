# Lab 02 blocks public IPs in Corp. Azure Firewall and Bastion each need one,
# so the hub resource group gets a time-limited exemption from that one rule.
locals {
  corp_deny_public_ip_assignment_id = "/providers/Microsoft.Management/managementGroups/mg-${var.prefix}-corp/providers/Microsoft.Authorization/policyAssignments/corp-deny-public-ip"
}

resource "azurerm_resource_group" "hub" {
  name     = "rg-${var.prefix}-hub-${var.location_short}"
  location = var.location

  tags = {
    "cost-centre" = "platform"
  }
}

resource "azurerm_resource_group_policy_exemption" "hub_public_ips" {
  name                 = "hub-public-ips"
  display_name         = "Hub firewall and Bastion public IPs"
  description          = "Azure Firewall and Azure Bastion need public IPs. Allowed in the hub resource group only, until the expiry date."
  resource_group_id    = azurerm_resource_group.hub.id
  policy_assignment_id = local.corp_deny_public_ip_assignment_id
  exemption_category   = "Waiver"
  expires_on           = var.exemption_expires_on
}

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-${var.prefix}-hub-${var.location_short}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  address_space       = [var.hub_address_space]
}

# Azure requires these exact subnet names, each at least /26
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [cidrsubnet(var.hub_address_space, 10, 4)]
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [cidrsubnet(var.hub_address_space, 10, 8)]
}

# The exemption must exist before Azure is asked for a public IP
resource "azurerm_public_ip" "firewall" {
  name                = "pip-${var.prefix}-fw-${var.location_short}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"

  depends_on = [azurerm_resource_group_policy_exemption.hub_public_ips]
}

resource "azurerm_public_ip" "bastion" {
  name                = "pip-${var.prefix}-bas-${var.location_short}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"

  depends_on = [azurerm_resource_group_policy_exemption.hub_public_ips]
}

resource "azurerm_firewall_policy" "hub" {
  name                = "afwp-${var.prefix}-hub-${var.location_short}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  sku                 = "Standard"
}

resource "azurerm_firewall_policy_rule_collection_group" "spokes" {
  name               = "rcg-spokes"
  firewall_policy_id = azurerm_firewall_policy.hub.id
  priority           = 100

  # Spokes may ping each other, and nothing else
  network_rule_collection {
    name     = "allow-spoke-to-spoke"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "icmp-between-spokes"
      protocols             = ["ICMP"]
      source_addresses      = local.spoke_address_spaces
      destination_addresses = local.spoke_address_spaces
      destination_ports     = ["*"]
    }
  }

  # Spokes may only reach approved websites
  application_rule_collection {
    name     = "allow-approved-websites"
    priority = 200
    action   = "Allow"

    rule {
      name = "approved-fqdns"

      protocols {
        type = "Http"
        port = 80
      }

      protocols {
        type = "Https"
        port = 443
      }

      source_addresses  = local.spoke_address_spaces
      destination_fqdns = var.allowed_fqdns
    }
  }
}

resource "azurerm_firewall" "hub" {
  name                = "afw-${var.prefix}-hub-${var.location_short}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.hub.id

  ip_configuration {
    name                 = "ipconfig"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}

resource "azurerm_bastion_host" "hub" {
  name                = "bas-${var.prefix}-hub-${var.location_short}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  sku                 = "Basic"

  ip_configuration {
    name                 = "ipconfig"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}