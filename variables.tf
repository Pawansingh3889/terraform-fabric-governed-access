variable "name" {
  type        = string
  description = "Prefix for every resource this module creates. Lowercase letters, digits and hyphens."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,20}$", var.name))
    error_message = "name must start with a letter, use only lowercase letters, digits and hyphens, and be 3-21 characters (it is embedded in Key Vault and workspace names with their own length limits)."
  }
}

variable "location" {
  type        = string
  description = "Azure region for the resource group, Key Vault and Log Analytics workspace."
  default     = "uksouth"
}

variable "workspace_display_name" {
  type        = string
  description = "Display name for the governed Fabric workspace. Defaults to the module name."
  default     = null
}

variable "capacity_id" {
  type        = string
  description = "Fabric capacity to assign the workspace to. Null leaves the workspace on shared/trial capacity."
  default     = null
}

variable "break_glass_admin_group_object_id" {
  type        = string
  description = "Object id of an Entra security group granted workspace Admin for emergencies. Null (the default) means no human principal has any workspace role - the deploying identity and the gateway are the only ways in."
  default     = null
}

variable "secret_reader_object_ids" {
  type        = map(string)
  description = "Principals allowed to read the gateway client secret from Key Vault, keyed by a short label (e.g. { runtime = \"<object-id>\" }). Typically the identity of whatever runs the gateway container."
  default     = {}
}

variable "secret_rotation_days" {
  type        = number
  description = "How often the gateway client secret is rotated on apply."
  default     = 90

  validation {
    condition     = var.secret_rotation_days >= 7 && var.secret_rotation_days <= 365
    error_message = "secret_rotation_days must be between 7 and 365."
  }
}

variable "log_retention_days" {
  type        = number
  description = "Retention for the audit Log Analytics workspace."
  default     = 30

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "log_retention_days must be between 30 and 730 (Log Analytics limits)."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every Azure resource."
  default     = {}
}
