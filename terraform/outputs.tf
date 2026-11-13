output "web_public_ip" {
  description = "Public IPv4 address of vm-web-prod"
  value       = azurerm_public_ip.web_pip.ip_address
}

output "backup_public_ip" {
  description = "Public IPv4 address of vm-backup-prod"
  value       = azurerm_public_ip.backup_pip.ip_address
}

output "web_private_ip" {
  description = "Private subnet IPv4 address of vm-web-prod"
  value       = azurerm_network_interface.web_nic.private_ip_address
}

output "backup_private_ip" {
  description = "Private subnet IPv4 address of vm-backup-prod"
  value       = azurerm_network_interface.backup_nic.private_ip_address
}

output "vm_ip_mappings" {
  description = "Complete hostname-to-IP mapping for Web and Backup VMs"
  value = {
    vm-web-prod = {
      public_ip  = azurerm_public_ip.web_pip.ip_address
      private_ip = azurerm_network_interface.web_nic.private_ip_address
      subnet     = azurerm_subnet.web.name
    }
    vm-backup-prod = {
      public_ip  = azurerm_public_ip.backup_pip.ip_address
      private_ip = azurerm_network_interface.backup_nic.private_ip_address
      subnet     = azurerm_subnet.backup.name
    }
  }
}
