# variables.tf for identity module

variable "identity_name" {
  description = "Name of the identity module"
  type        = string
}

variable "common_tags" {
  description = "values to apply as common tags across resources"
  type        = map(string)
  default     = {}
}

variable "organization" {
  description = "Organization name for tagging and resource naming"
  type        = string      
}

variable "organization_name" {
  description = "Organization name"
  type        = string
}

variable "sso_config" {
  description = "SSO configuration"
  type = object({
    enable_sso       = bool
    session_duration = string
    identity_store_id = string
  })
}

variable "permission_sets" {
  description = "Permission sets configuration"
  type = map(object({
    description      = string
    session_duration = string
    managed_policies = list(string)
  }))
}
