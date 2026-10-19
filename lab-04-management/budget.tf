# One alert per threshold. Forecasted fires when Azure predicts the month will go over
locals {
  budget_alerts = {
    "actual-50"    = { threshold = 50, type = "Actual" }
    "actual-80"    = { threshold = 80, type = "Actual" }
    "actual-100"   = { threshold = 100, type = "Actual" }
    "forecast-100" = { threshold = 100, type = "Forecasted" }
  }
}

resource "azurerm_consumption_budget_subscription" "monthly" {
  name            = "budget-${var.prefix}-monthly"
  subscription_id = data.azurerm_subscription.current.id
  amount          = var.budget_amount
  time_grain      = "Monthly"

  time_period {
    start_date = var.budget_start_date
  }

  dynamic "notification" {
    for_each = local.budget_alerts

    content {
      enabled        = true
      threshold      = notification.value.threshold
      threshold_type = notification.value.type
      operator       = "GreaterThanOrEqualTo"

      # Alerts go to whoever holds the Owner role, so no email address is stored in code
      contact_roles = ["Owner"]
    }
  }
}