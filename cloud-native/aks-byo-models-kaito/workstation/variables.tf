variable "location" {
  type        = string
  default     = "brazilsouth"
  description = "value of location"
}

variable "vm_size" {
  type        = string
  default     = "Standard_D8s_v4"
  description = "size of the virtual machine"
}

variable "vm_username" {
  type        = string
  default     = "paul"
  description = "username for SSH access"
}