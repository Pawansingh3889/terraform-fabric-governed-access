output "workspace_id" {
  description = "Id of the governed Fabric workspace."
  value       = fabric_workspace.governed.id
}

output "gateway_client_id" {
  description = "Client id the gateway authenticates with."
  value       = azuread_application.gateway.client_id
}

output "gateway_principal_object_id" {
  description = "Object id of the gateway service principal - the sole data-plane principal on the workspace."
  value       = azuread_service_principal.gateway.object_id
}

output "gateway_secret_key_vault_id" {
  description = "Key Vault holding the gateway client secret."
  value       = azurerm_key_vault.this.id
}

output "gateway_secret_name" {
  description = "Name of the Key Vault secret holding the gateway client secret."
  value       = azurerm_key_vault_secret.gateway_client_secret.name
}

output "audit_workspace_id" {
  description = "Resource id of the Log Analytics workspace the gateway ships its decision ledger to."
  value       = azurerm_log_analytics_workspace.audit.id
}

output "audit_workspace_customer_id" {
  description = "Log Analytics workspace (customer) id, needed by log ingestion clients."
  value       = azurerm_log_analytics_workspace.audit.workspace_id
}

output "data_plane_principals" {
  description = "Every principal this module EXPLICITLY grants a workspace role. With break_glass unset this is exactly one service principal. Note: Fabric also grants the deploying identity workspace Admin implicitly - that is not a role assignment and does not appear here, which is why the module must be deployed by an already-privileged pipeline identity (see README limitation 3)."
  value = concat(
    [{ role = "Contributor", type = "ServicePrincipal", object_id = azuread_service_principal.gateway.object_id }],
    var.break_glass_admin_group_object_id == null ? [] : [{ role = "Admin", type = "Group", object_id = var.break_glass_admin_group_object_id }]
  )
}
