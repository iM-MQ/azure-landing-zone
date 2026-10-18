terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-uks"
    storage_account_name = "sttfstateeji7qh"
    container_name       = "tfstate"
    key                  = "alz-lab03-hub-spoke.tfstate"
  }
}
