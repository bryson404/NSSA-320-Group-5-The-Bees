variable "location" {
  description = "Azure region for all deployed resources"
  type        = string
  default     = "eastus2"
}

variable "vm_size" {
  description = "Azure VM SKU size for Web and Backup nodes"
  type        = string
  default     = "Standard_B1s"
}

variable "ssh_key" {
  description = "ED25519 SSH public key string for VM administrator authentication"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^ssh-ed25519 ", trimspace(var.ssh_key)))
    error_message = "The ssh_key variable must be a valid ED25519 public key starting with 'ssh-ed25519 '."
  }
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "rg-nssa320-backup-demo"
}

variable "admin_username" {
  description = "Administrator username for the Linux VMs"
  type        = string
  default     = "azureuser"
}

variable "admin_ssh_cidr" {
  description = "Source CIDR allowed to SSH into VMs (RIT public IPv4 block is 129.21.0.0/16)"
  type        = string
  default     = "129.21.0.0/16"
}

variable "inventory_path" {
  description = "Output file path for the dynamically generated Ansible inventory.yml"
  type        = string
  default     = "../ansible/inventory.yml"
}
