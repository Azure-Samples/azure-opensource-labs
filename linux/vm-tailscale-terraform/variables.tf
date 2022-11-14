variable "tailnet_name" {
  type        = string
  description = "Tailnet name"
}

variable "tailscale_api_key" {
  type        = string
  sensitive   = true
  description = "Tailscale API key"
}

variable "location" {
  type        = string
  description = "Azure region to deploy resources into"
  default     = "westus3"
}

variable "tags" {
  type = map(any)
  default = {
    repo = "Azure-Samples/azure-opensource-labs"
    lab  = "linux/vm/vm-tailscale-terraform"
  }
}

variable "vnet_address_space" {
  type        = string
  description = "Virtual network address space in CIDR notation"
  default     = "10.0.0.0/16"
}

variable "snet_address_space" {
  type        = string
  description = "Subnet address space in CIDR notation"
  default     = "10.0.0.0/24"
}

variable "vm_sku" {
  type        = string
  description = "Size of the Azure Virtual Machine"
  default     = "Standard_D4s_v5"
}

variable "vm_username" {
  type        = string
  description = "Local admin username"
  default     = "azureuser"
}

variable "vm_os_disk_storage_type" {
  type        = string
  description = "The OS disk storage type"
  default     = "Premium_LRS"
  validation {
    condition = can(index([
      "Standard_LRS",
      "StandardSSD_LRS",
      "Premium_LRS",
      "StandardSSD_ZRS",
      "Premium_ZRS"
    ], var.vm_os_disk_storage_type) >= 0)
    error_message = "Invalid OS disk storage type"
  }
}

variable "vm_source_image" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  description = "The source image to use"
  default = {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}