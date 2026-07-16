# The audit sink. The gateway ships its decision ledger (every allowed
# and denied statement, with policy verdicts) here - that is the SIEM
# feed. Fabric's own tenant-level audit lives in Microsoft Purview and
# is not an ARM surface this module can wire up; the README is explicit
# about that boundary.

resource "azurerm_log_analytics_workspace" "audit" {
  name                = "${var.name}-audit"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days

  tags = var.tags
}
