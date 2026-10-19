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
  description = "Azure region for the management resources"
  type        = string
  default     = "uksouth"

  validation {
    condition     = contains(["uksouth", "ukwest"], var.location)
    error_message = "The location must be uksouth or ukwest, to match the allowed locations policy from Lab 02."
  }
}

variable "location_short" {
  description = "Short region code used in resource names"
  type        = string
  default     = "uks"
}

variable "log_retention_days" {
  description = "How long the workspace keeps logs"
  type        = number
  default     = 30

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "Retention must be between 30 and 730 days."
  }
}

variable "daily_quota_gb" {
  description = "Daily ingestion cap for the workspace, so a noisy source cannot run up a bill"
  type        = number
  default     = 0.5

  validation {
    condition     = var.daily_quota_gb > 0
    error_message = "The daily cap must be greater than zero."
  }
}

variable "activity_log_categories" {
  description = "Subscription activity log categories sent to the workspace"
  type        = list(string)
  default = [
    "Administrative",
    "Security",
    "ServiceHealth",
    "Alert",
    "Recommendation",
    "Policy",
    "Autoscale",
    "ResourceHealth",
  ]
}

variable "budget_amount" {
  description = "Monthly budget for the subscription, in the billing currency"
  type        = number
  default     = 20

  validation {
    condition     = var.budget_amount > 0
    error_message = "The budget must be greater than zero."
  }
}

variable "budget_start_date" {
  description = "First month the budget applies to. Must be the first day of a month, in UTC"
  type        = string
  default     = "2026-10-01T00:00:00Z"

  validation {
    condition     = can(regex("^[0-9]{4}-[0-9]{2}-01T00:00:00Z$", var.budget_start_date))
    error_message = "The start date must be the first day of a month, such as 2026-10-01T00:00:00Z."
  }
}

variable "reader_group_name" {
  description = "Entra ID group given read-only access to the whole landing zone"
  type        = string
  default     = "grp-alz-platform-readers"
}