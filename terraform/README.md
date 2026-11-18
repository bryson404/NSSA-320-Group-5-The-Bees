# NSSA 320 — Automated Backup & Recovery Infrastructure (Terraform)

This directory contains the Infrastructure as Code (IaC) configuration for **Slot 5B: Automated Backup and Recovery Service**. It provisions an isolated Azure virtual network, network security groups, static IPs, and two Ubuntu 22.04 LTS virtual machines (`vm-web-prod` and `vm-backup-prod`), and automatically generates an Ansible `inventory.yml` file upon deployment.

## Architecture Overview

| Resource | Azure Name | Configuration / Details | 
| ----- | ----- | ----- | 
| **Resource Group** | `rg-nssa320-backup-demo` | Region: `eastus2` (configurable via `location`) | 
| **Virtual Network** | `vnet-nssa320-backup` | Address space: `10.0.0.0/16` | 
| **Web Subnet & NSG** | `subnet-web` / `nsg-web` | `10.0.1.0/24` — Inbound HTTP (`80`) public; SSH (`22`) from RIT & Backup subnet | 
| **Backup Subnet & NSG** | `subnet-backup` / `nsg-backup` | `10.0.2.0/24` — Inbound SSH (`22`) from RIT & Web subnet only | 
| **Web Server VM** | `vm-web-prod` | `Standard_B1s`, Ubuntu 22.04 LTS, 30 GB Standard SSD, Private IP `10.0.1.10` | 
| **Backup Server VM** | `vm-backup-prod` | `Standard_B1s`, Ubuntu 22.04 LTS, 64 GB Premium SSD, Private IP `10.0.2.10` (`prevent_destroy = true`) | 
| **Public IPs** | `pip-web-prod`, `pip-backup-prod` | Standard SKU, Static allocation (persists across Web VM rebuilds) | 

## Repository Structure

```
terraform/
├── providers.tf               # Terraform (>= 1.5.0) & AzureRM (~> 4.0) provider config
├── variables.tf               # Input variables (location, vm_size, ssh_key, admin_ssh_cidr, etc.)
├── network.tf                 # Resource group, VNet, subnets, NSGs, static Public IPs, NICs
├── compute.tf                 # Web & Backup VMs, lifecycle guard, local-exec inventory trigger
├── outputs.tf                 # Exposed VM public/private IP outputs & mappings
├── terraform.tfvars.example   # Template for local variable overrides
└── .gitignore                 # Excludes .terraform/, *.tfstate, and *.tfvars from Git

```

## 1. Prerequisites

Ensure the following tools are installed on your workstation:

1. **Terraform (`>= 1.5.0`)**

2. **Azure CLI (`az`)** — [Install Guide](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)

3. **OpenSSH Client (`ssh-keygen`) or method to generate public/private key pair**

## 2. Initial Setup Steps

### Step 1: Generate an ED25519 SSH Key Pair

All VMs disable password authentication and require an ED25519 public key. If you do not already have one at `~/.ssh/id_ed25519`:

```
ssh-keygen -t ed25519 -C "your_email@rit.edu"
chmod 600 ~/.ssh/id_ed25519

```

*(Press **Enter** at the passphrase prompt if you want passwordless Ansible execution, or load your key into your session agent with `ssh-add ~/.ssh/id_ed25519`.)*

Print your public key and copy the single-line output:

```
cat ~/.ssh/id_ed25519.pub
```

### Step 2: Authenticate with Azure & Select the Shared Subscription

All team members must target the **same** Azure subscription so everyone shares the same remote state and infrastructure:

```
az login
```

### Step 3: Configure Local Variables (`terraform.tfvars`)

Create your local `terraform.tfvars` file (ignored by Git) from the example template:

```
cd terraform
cp terraform.tfvars.example terraform.tfvars

```

Edit `terraform.tfvars` with your ED25519 public key and network settings:

```
location       = "eastus2"
vm_size        = "Standard_B1s"
ssh_key        = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... your_email@rit.edu"
admin_ssh_cidr = "129.21.0.0/16"
inventory_path = "../ansible/inventory.yml"

```

> **Off-Campus Access:** `129.21.0.0/16` restricts inbound SSH to RIT's campus/VPN network. If you are deploying or running Ansible from home without the RIT VPN, set `admin_ssh_cidr = "*"` (or `"<YOUR_PUBLIC_IP>/32"`).

## 3. Deploying the Infrastructure

From inside the `terraform/` directory, run the following commands in order:

1. **Initialize providers and backend:**

   ```
   terraform init
   ```

2. **Format and validate the configuration:**

   ```
   terraform fmt -check
   terraform validate
   ```

3. **Generate and review the execution plan:**

   ```
   terraform plan -out=tfplan
   ```

   *(Verify that Terraform plans to create the Resource Group, VNet, 2 Subnets, 2 NSGs, 2 NSG Associations, 2 Public IPs, 2 NICs, 2 Virtual Machines, and the inventory generator resource.)*

4. **Apply the plan to provision Azure resources:**

   ```
   terraform apply tfplan
   ```

   When `terraform apply` finishes, it automatically  populates host IPs to `../ansible/inventory.yml`.
