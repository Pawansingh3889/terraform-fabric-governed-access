# The governed workspace and its front door.
#
# Enforcement model: the gateway service principal is the only principal
# assigned a data role here. The identity that RUNS terraform is
# implicitly workspace Admin (Fabric grants the creator Admin - there is
# no way around that, and the README says so rather than pretending
# otherwise). Humans get nothing unless you opt into the break-glass
# group.
#
# The fabric provider cannot yet manage item-level (per-lakehouse)
# permissions - microsoft/terraform-provider-fabric#425 - so
# workspace-level exclusivity IS the enforcement boundary. When per-item
# ACLs land, this module tightens.

resource "fabric_workspace" "governed" {
  display_name = local.workspace_display_name
  description  = "Governed workspace: data access only via the gateway service principal. Managed by terraform-fabric-governed-access."
  capacity_id  = var.capacity_id
}

resource "fabric_workspace_role_assignment" "gateway_contributor" {
  workspace_id = fabric_workspace.governed.id

  principal = {
    id   = azuread_service_principal.gateway.object_id
    type = "ServicePrincipal"
  }

  # Contributor can read and write items but cannot manage access -
  # the gateway must never be able to widen the door it guards.
  role = "Contributor"
}

resource "fabric_workspace_role_assignment" "break_glass_admin" {
  count = var.break_glass_admin_group_object_id == null ? 0 : 1

  workspace_id = fabric_workspace.governed.id

  principal = {
    id   = var.break_glass_admin_group_object_id
    type = "Group"
  }

  role = "Admin"
}
