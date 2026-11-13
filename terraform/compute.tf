# Web Server VM
resource "azurerm_linux_virtual_machine" "web_vm" {
  name                            = "vm-web-prod"
  computer_name                   = "vm-web-prod"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.web_nic.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = trimspace(var.ssh_key)
  }

  os_disk {
    name                 = "osdisk-web-prod"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    Role = "webserver"
  }
}

# Backup Server VM
resource "azurerm_linux_virtual_machine" "backup_vm" {
  name                            = "vm-backup-prod"
  computer_name                   = "vm-backup-prod"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.backup_nic.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = trimspace(var.ssh_key)
  }

  os_disk {
    name                 = "osdisk-backup-prod"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 64
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    Role = "backupserver"
  }

  # Safeguard against accidental destruction during DR rebuild tests
  lifecycle {
    prevent_destroy = false
  }
}

# Dynamically generate Ansible inventory.yml
resource "null_resource" "generate_ansible_inventory" {
  triggers = {
    web_vm_id        = azurerm_linux_virtual_machine.web_vm.id
    backup_vm_id     = azurerm_linux_virtual_machine.backup_vm.id
    web_public_ip    = azurerm_public_ip.web_pip.ip_address
    backup_public_ip = azurerm_public_ip.backup_pip.ip_address
  }

  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p "$(dirname "${var.inventory_path}")"
      cat << 'EOF' > "${var.inventory_path}"
      all:
        vars:
          ansible_user: ${var.admin_username}
          ansible_ssh_private_key_file: ~/.ssh/id_ed25519
          ansible_python_interpreter: /usr/bin/python3
        children:
          webservers:
            hosts:
              vm-web-prod:
                ansible_host: ${azurerm_public_ip.web_pip.ip_address}
                private_ip: ${azurerm_network_interface.web_nic.private_ip_address}
          backupservers:
            hosts:
              vm-backup-prod:
                ansible_host: ${azurerm_public_ip.backup_pip.ip_address}
                private_ip: ${azurerm_network_interface.backup_nic.private_ip_address}
      EOF
    EOT
  }

  depends_on = [
    azurerm_linux_virtual_machine.web_vm,
    azurerm_linux_virtual_machine.backup_vm
  ]
}
