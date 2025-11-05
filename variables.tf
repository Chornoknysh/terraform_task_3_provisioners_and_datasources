variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Existing resource group created in the Azure portal"
  type        = string
}

variable "vnet_name" {
  description = "Existing virtual network name"
  type        = string
}

variable "subnet_name" {
  description = "Existing subnet name"
  type        = string
}

variable "nic_name" {
  description = "Existing network interface name"
  type        = string
}

variable "public_ip_name" {
  description = "Existing public IP attached to NIC/VM"
  type        = string
}

variable "vm_name" {
  description = "Existing virtual machine name"
  type        = string
}

variable "ssh_username" {
  description = "Admin username on the Linux VM"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to your local SSH private key for the VM"
  type        = string
}
