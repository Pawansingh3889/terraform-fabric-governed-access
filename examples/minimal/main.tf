# Minimal example: a governed workspace on trial/shared capacity, no
# break-glass group, no secret readers yet.
#
# Auth: `az login` first. The fabric provider picks up Azure CLI
# credentials; your user needs permission to create Entra applications
# and a Fabric license (the free trial is enough).

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
    fabric = {
      source  = "microsoft/fabric"
      version = ">= 1.0, < 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

provider "fabric" {
  # Azure CLI auth; set use_cli = false and SP credentials for pipelines.
}

module "governed_fabric" {
  source = "../.."

  name     = "govfab-demo"
  location = "uksouth"

  tags = {
    purpose = "governed-fabric-demo"
  }
}

output "data_plane_principals" {
  value = module.governed_fabric.data_plane_principals
}

output "workspace_id" {
  value = module.governed_fabric.workspace_id
}
