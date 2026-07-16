# Key Vault holds the gateway's client secret so the runtime never sees
# it in config files or pipeline variables. RBAC authorization only - no
# access policies.

resource "azurerm_key_vault" "this" {
  name                = local.key_vault_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  rbac_authorization_enabled = true

  # Deliberately destroyable for lab/demo tenants. Flip purge protection
  # on for anything long-lived - documented in the README.
  purge_protection_enabled   = false
  soft_delete_retention_days = 7

  tags = var.tags
}

# The deploying identity needs to write the secret it is about to store.
resource "azurerm_role_assignment" "deployer_secrets_officer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "gateway_client_secret" {
  name         = "${var.name}-gateway-client-secret"
  value        = azuread_application_password.gateway.value
  key_vault_id = azurerm_key_vault.this.id
  content_type = "entra-client-secret"

  # RBAC propagation is not instant; without this the first apply races
  # the role assignment and fails with 403.
  depends_on = [azurerm_role_assignment.deployer_secrets_officer]
}

# Whoever runs the gateway reads the secret at startup.
resource "azurerm_role_assignment" "secret_readers" {
  for_each = var.secret_reader_object_ids

  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value
}
