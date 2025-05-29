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

variable "vm_image_offer" {
  type        = string
  default     = "ubuntu-24_04-lts"
  description = "publisher of the virtual machine image - look up additional offers with `az vm image list-offers -l <your_location> -p canonical --query \"[].name\" -o tsv`"
}

variable "vm_username" {
  type        = string
  default     = "paul"
  description = "username for SSH access"
}