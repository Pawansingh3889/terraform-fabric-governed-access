terraform {
  required_version = ">= 1.8"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    # Public preview provider - pinned below 2.0 on purpose. See README
    # for what that means and which features wait on it.
    fabric = {
      source  = "microsoft/fabric"
      version = ">= 1.0, < 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}
