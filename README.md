# terraform-fabric-governed-access

Provision a Microsoft Fabric workspace where the only path to the data is
through your policy gateway.

Most "governance" modules tag resources and call it a day. This one wires
identity so that governance has teeth: the only principal it *grants* a
data role is a service principal your enforcement gateway runs as. No
human is granted a workspace role (the deploying pipeline identity is an
implicit Admin - see limitations). An agent, a notebook, a BI tool -
anything that wants the data - talks to the gateway, and it applies policy
(allow the SELECT, refuse the DROP, log both) before anything reaches
Fabric. If a request does not go through the gateway, there is no
identity for it to use.

```
                      +---------------------------+
  agents / users ---> |  gateway (your container: |      +-----------------+
                      |  policy + audit ledger)   | ---> | Fabric workspace|
                      +------------+--------------+  SP  |  (no other      |
                                   |                     |   principals)   |
                                   v                     +-----------------+
                      +---------------------------+
                      |  Log Analytics (ledger)   |
                      +---------------------------+
```

## What it creates

- An Entra application + service principal for the gateway, with a
  client secret rotated on a schedule (default 90 days)
- A Key Vault (RBAC mode) holding that secret; you grant your runtime
  read access via `secret_reader_object_ids`
- A Log Analytics workspace for the gateway's decision ledger - the
  audit trail of every allowed and denied statement
- A Fabric workspace with exactly one data role assignment: the gateway
  service principal as Contributor (it can use the data, it can never
  widen the door - access management needs Admin)
- Optionally, one break-glass Admin group for emergencies

The `data_plane_principals` output lists every principal the module
granted a role. With break-glass unset it is exactly one service
principal - that output is the reviewable assertion this module exists
to make.

## What it deliberately is not

- Not a landing zone. Use CAF/ALZ for subscriptions, networks and
  policy assignments; this module does one narrow thing under them.
- Not the gateway itself. The gateway is your code (any container that
  authenticates with the client id/secret this module mints). This
  module is the infrastructure contract around it.
- Not a Purview replacement. Fabric tenant auditing lives in Purview
  and is not an ARM surface Terraform can attach diagnostics to. The
  Log Analytics workspace here is the sink for the gateway's own
  ledger, which is the record of policy decisions - a different and
  complementary trail.

## Usage

```hcl
module "governed_fabric" {
  source = "github.com/Pawansingh3889/terraform-fabric-governed-access"

  name     = "govfab-prod"
  location = "uksouth"

  capacity_id = fabric_capacity.prod.id # optional; omit on trial capacity

  secret_reader_object_ids = {
    runtime = azurerm_container_app.gateway.identity[0].principal_id
  }

  break_glass_admin_group_object_id = azuread_group.platform_admins.object_id # optional
}
```

Auth: `az login` (the fabric provider rides Azure CLI credentials by
default) or a service principal for pipelines. The deploying identity
needs rights to create Entra applications, and a Fabric license (the
free trial works).

## Honest limitations - read before trusting

1. **The fabric provider is in public preview.** This module pins
   `>= 1.0, < 2.0` and tracks it knowingly. Expect the provider to move.
2. **Item-level permissions do not exist in the provider yet**
   ([microsoft/terraform-provider-fabric#425](https://github.com/microsoft/terraform-provider-fabric/issues/425)).
   Workspace-level exclusivity is therefore the enforcement boundary:
   nothing but the gateway holds any role, so there is no finer grain to
   miss. When per-item ACLs land, this module will tighten to
   least-privilege per lakehouse.
3. **The deploying identity is workspace Admin.** Fabric grants the
   creator Admin and that cannot be avoided. Deploy with a pipeline
   identity you already treat as privileged, not a personal account.
4. **Terraform state contains the client secret.** The
   `azuread_application_password` value passes through state on its way
   to Key Vault. Use an encrypted remote backend with tight access -
   this is true of any Terraform-managed credential and the reason v0.2
   moves to federated credentials.
5. **Rotation is apply-time.** `time_rotating` rotates the secret when
   an apply runs after the rotation window, not on a wall clock. Run
   applies at least as often as your rotation period, or wire a
   scheduled pipeline.

## Roadmap

- v0.2: federated (workload identity) credentials for the gateway -
  no client secret, no state exposure, no rotation clock
- Per-item (lakehouse/warehouse) role assignments when the provider
  ships them
- Optional Data Collection Rule + endpoint so the ledger flows through
  the Logs Ingestion API natively

## Inputs

| Name | Description | Default |
|------|-------------|---------|
| `name` | Prefix for everything (3-21 chars, lowercase) | required |
| `location` | Azure region | `uksouth` |
| `workspace_display_name` | Fabric workspace display name | `name` |
| `capacity_id` | Fabric capacity id | `null` (shared/trial) |
| `break_glass_admin_group_object_id` | Entra group given workspace Admin | `null` (nobody) |
| `secret_reader_object_ids` | Principals that may read the gateway secret | `{}` |
| `secret_rotation_days` | Client secret rotation window | `90` |
| `log_retention_days` | Ledger retention | `30` |
| `tags` | Tags for Azure resources | `{}` |

## Outputs

`workspace_id`, `gateway_client_id`, `gateway_principal_object_id`,
`gateway_secret_key_vault_id`, `gateway_secret_name`,
`audit_workspace_id`, `audit_workspace_customer_id`,
`data_plane_principals`.
