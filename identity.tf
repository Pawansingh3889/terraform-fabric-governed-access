# The gateway's identity. This service principal is the ONLY principal
# granted a data role on the workspace - it is the front door.

resource "azuread_application" "gateway" {
  display_name = "${var.name}-gateway"

  # The gateway authenticates as itself; no delegated user consent.
  sign_in_audience = "AzureADMyOrg"
}

resource "azuread_service_principal" "gateway" {
  client_id = azuread_application.gateway.client_id
}

# Client secret, rotated on a schedule. A secret is the v0.1 shape so the
# module works on any runtime; federated (workload identity) credentials
# are the planned v0.2 upgrade - see the README roadmap.
resource "time_rotating" "gateway_secret" {
  rotation_days = var.secret_rotation_days
}

resource "azuread_application_password" "gateway" {
  application_id = azuread_application.gateway.id
  display_name   = "gateway-runtime"

  rotate_when_changed = {
    rotation = time_rotating.gateway_secret.id
  }
}
