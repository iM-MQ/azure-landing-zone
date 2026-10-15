variable "prefix" {
  description = "The organisation prefix used in Lab 01's management group names"
  type        = string
  default     = "alz"
}

variable "allowed_locations" {
  description = "Azure regions where resources and resource groups may be created"
  type        = list(string)
  default     = ["uksouth", "ukwest"]

  validation {
    condition     = length(var.allowed_locations) > 0
    error_message = "At least one region must be allowed, or nothing could ever be deployed."
  }
}

variable "required_tag" {
  description = "Tag that every resource group in the landing zones must have"
  type        = string
  default     = "cost-centre"
}

variable "corp_denied_resource_types" {
  description = "Resource types that are not allowed in Corp landing zones"
  type        = list(string)
  default     = ["Microsoft.Network/publicIPAddresses"]
}