# terraform-fabric-governed-access
#
# Provisions a Fabric workspace whose only data-plane principal is a
# gateway service principal - the identity your policy-enforcing SQL
# gateway runs as. Humans get no workspace role by default; every query
# path goes through the gateway or it does not exist.
#
# The module is composable: it creates the governed workspace and the
# gateway's identity, secret and audit sink, and expects you to deploy
# the gateway itself (a container running your enforcement layer)
# wherever suits - it consumes the outputs of this module.

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "this" {
  name     = "${var.name}-rg"
  location = var.location
  tags     = var.tags
}

# Key Vault names are 3-24 chars, globally unique, alphanumeric + hyphen.
resource "random_string" "kv_suffix" {
  length  = 5
  lower   = true
  numeric = true
  upper   = false
  special = false
}

locals {
  workspace_display_name = coalesce(var.workspace_display_name, var.name)
  key_vault_name         = "${substr(replace(var.name, "-", ""), 0, 18)}${random_string.kv_suffix.result}"
}
