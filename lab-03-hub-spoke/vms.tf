# One small test VM per spoke, with no public IP. Reached through Bastion only
resource "azurerm_network_interface" "vm" {
  for_each = var.spokes

  name                = "nic-${var.prefix}-${each.key}-${var.location_short}"
  location            = azurerm_resource_group.spoke[each.key].location
  resource_group_name = azurerm_resource_group.spoke[each.key].name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.workload[each.key].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  for_each = var.spokes

  name                  = "vm-${var.prefix}-${each.key}"
  location              = azurerm_resource_group.spoke[each.key].location
  resource_group_name   = azurerm_resource_group.spoke[each.key].name
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.vm[each.key].id]

  # v7 sizes only support the NVMe disk controller
  disk_controller_type = "NVMe"

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(pathexpand(var.ssh_public_key_path))
  }

  os_disk {
    name                 = "osdisk-${var.prefix}-${each.key}"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  boot_diagnostics {}

  # Routing and NSG rules are in place before the VM starts
  depends_on = [
    azurerm_subnet_route_table_association.spoke,
    azurerm_subnet_network_security_group_association.spoke,
  ]
}