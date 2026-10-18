output "firewall_private_ip" {
  description = "Next hop for all spoke traffic"
  value       = azurerm_firewall.hub.ip_configuration[0].private_ip_address
}

output "vm_private_ips" {
  description = "Private IP of each test VM"
  value       = { for k, nic in azurerm_network_interface.vm : k => nic.private_ip_address }
}

output "bastion_name" {
  description = "Bastion host used to reach the VMs"
  value       = azurerm_bastion_host.hub.name
}

output "exemption_expires_on" {
  description = "When the hub's public IP exemption stops applying"
  value       = azurerm_resource_group_policy_exemption.hub_public_ips.expires_on
}