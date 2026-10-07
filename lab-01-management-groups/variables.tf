variable "prefix" {
  description = "Short name for the organisation, used in every management group name"
  type        = string
  default     = "alz"

  validation {
    condition     = can(regex("^[a-z0-9]{2,10}$", var.prefix))
    error_message = "The prefix must be 2 to 10 lowercase letters or numbers."
  }
}

variable "subscription_placement" {
  description = "Which management group the lab subscription is placed in"
  type        = string
  default     = "corp"

  validation {
    condition     = contains(["connectivity", "identity", "management", "corp", "online"], var.subscription_placement)
    error_message = "The subscription must go in connectivity, identity, management, corp or online."
  }
}