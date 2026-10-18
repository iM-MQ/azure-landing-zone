variable "prefix" {
  description = "Short name for the organisation, used in every resource name"
  type        = string
  default     = "alz"

  validation {
    condition     = can(regex("^[a-z0-9]{2,10}$", var.prefix))
    error_message = "The prefix must be 2 to 10 lowercase letters or numbers."
  }
}

variable "location" {
  description = "Azure region for the hub and spokes"
  type        = string
  default     = "ukwest"

  validation {
    condition     = contains(["uksouth", "ukwest"], var.location)
    error_message = "The location must be uksouth or ukwest, to match the allowed locations policy from Lab 02."
  }
}

variable "location_short" {
  description = "Short region code used in resource names"
  type        = string
  default     = "ukw"
}

variable "hub_address_space" {
  description = "Address space for the hub virtual network"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.hub_address_space, 0))
    error_message = "The hub address space must be a valid CIDR range, such as 10.0.0.0/16."
  }
}

variable "spokes" {
  description = "Spoke networks, each with its address space and the cost centre that pays for it"
  type = map(object({
    address_space = string
    cost_centre   = string
  }))
  default = {
    spoke1 = { address_space = "10.1.0.0/16", cost_centre = "app1" }
    spoke2 = { address_space = "10.2.0.0/16", cost_centre = "app2" }
  }

  validation {
    condition     = alltrue([for s in values(var.spokes) : can(cidrhost(s.address_space, 0))])
    error_message = "Every spoke address space must be a valid CIDR range, such as 10.1.0.0/16."
  }
}

variable "vm_size" {
  description = "Size of the test VMs. The free trial only allows v7 sizes in UK West"
  type        = string
  default     = "Standard_F1als_v7"
}

variable "admin_username" {
  description = "Admin user on the test VMs"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key put on the test VMs"
  type        = string
  default     = "~/.ssh/alz-lab03.pub"
}

variable "exemption_expires_on" {
  description = "When the hub's public IP exemption stops applying, in UTC"
  type        = string
  default     = "2026-11-30T23:59:59Z"

  validation {
    condition     = try(timecmp(var.exemption_expires_on, plantimestamp()) > 0, false)
    error_message = "The exemption expiry must be a future date in RFC 3339 format, such as 2026-11-30T23:59:59Z."
  }
}

variable "allowed_fqdns" {
  description = "Websites the spoke VMs may reach through the firewall"
  type        = list(string)
  default     = ["*.ubuntu.com", "www.microsoft.com"]
}