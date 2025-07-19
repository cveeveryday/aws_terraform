# variables.tf for automation module

variable "automation_name" {
  description = "Name of the automation module"
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

# Automation Module Variables
variable "git_repositories" {
  description = "Git repositories to create"
  type = list(object({
    name        = string
    description = string
  }))
}

variable "pipeline_config" {
  description = "CI/CD Pipeline configuration"
  type = object({
    enable_cross_account_deploy = bool
    artifact_retention_days     = number
    enable_approval_stage      = bool
  })
}

variable "backup_config" {
  description = "Backup configuration"
  type = object({
    enable_point_in_time_recovery = bool
    backup_retention_days         = number
    enable_cross_region_backup    = bool
    backup_region                = string
  })
}