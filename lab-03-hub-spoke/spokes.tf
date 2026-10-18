locals {
  spoke_address_spaces = [for s in values(var.spokes) : s.address_space]
}

resource "azurerm_resource_group" "spoke" {
  for_each = var.spokes

  name     = "rg-${var.prefix}-${each.key}-${var.location_short}"
  location = var.location

  tags = {
    "cost-centre" = each.value.cost_centre
  }
}

resource "azurerm_virtual_network" "spoke" {
  for_each = var.spokes

  name                = "vnet-${var.prefix}-${each.key}-${var.location_short}"
  location            = azurerm_resource_group.spoke[each.key].location
  resource_group_name = azurerm_resource_group.spoke[each.key].name
  address_space       = [each.value.address_space]
}

resource "azurerm_subnet" "workload" {
  for_each = var.spokes

  name                 = "snet-workload"
  resource_group_name  = azurerm_resource_group.spoke[each.key].name
  virtual_network_name = azurerm_virtual_network.spoke[each.key].name
  address_prefixes     = [cidrsubnet(each.value.address_space, 8, 1)]
}

# Peering is one-way, so each spoke needs a link in both directions
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each = var.spokes

  name                      = "peer-hub-to-${each.key}"
  resource_group_name       = azurerm_resource_group.hub.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke[each.key].id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  for_each = var.spokes

  name                      = "peer-${each.key}-to-hub"
  resource_group_name       = azurerm_resource_group.spoke[each.key].name
  virtual_network_name      = azurerm_virtual_network.spoke[each.key].name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
  allow_forwarded_traffic   = true
}

# Send everything that is not local or in the hub to the firewall
resource "azurerm_route_table" "spoke" {
  for_each = var.spokes

  name                          = "rt-${var.prefix}-${each.key}-${var.location_short}"
  location                      = azurerm_resource_group.spoke[each.key].location
  resource_group_name           = azurerm_resource_group.spoke[each.key].name
  bgp_route_propagation_enabled = false

  route {
    name                   = "default-via-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.hub.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "spoke" {
  for_each = var.spokes

  subnet_id      = azurerm_subnet.workload[each.key].id
  route_table_id = azurerm_route_table.spoke[each.key].id
}

resource "azurerm_network_security_group" "spoke" {
  for_each = var.spokes

  name                = "nsg-${var.prefix}-${each.key}-${var.location_short}"
  location            = azurerm_resource_group.spoke[each.key].location
  resource_group_name = azurerm_resource_group.spoke[each.key].name

  security_rule {
    name                       = "allow-ssh-from-bastion"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = azurerm_subnet.bastion.address_prefixes[0]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-icmp-from-spokes"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes    = local.spoke_address_spaces
    destination_address_prefix = "*"
  }

  # Overrides Azure's default rule that allows all traffic between connected networks
  security_rule {
    name                       = "deny-other-vnet-inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "spoke" {
  for_each = var.spokes

  subnet_id                 = azurerm_subnet.workload[each.key].id
  network_security_group_id = azurerm_network_security_group.spoke[each.key].id
}