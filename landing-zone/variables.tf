# Root variables.tf

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "organization_name" {
  description = "Name of the organization"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., prod, dev)"
  type        = string
}

variable "cost_center" {
  description = "Cost center for tagging resources"
  type        = string
}

variable "primary_region" {
  description = "Primary AWS region for multi-region deployments"
  type        = string
}

variable "secondary_region" {
  description = "Secondary AWS region for multi-region deployments"
  type        = string
}

variable "applications" {
  description = "Map of application configurations for the landing zone."
  type = object({
    web_app = object({
      name           = string
      vpc_cidr_base  = string
    })
    api_service = object({
      name           = string
      vpc_cidr_base  = string
    })
  })
}
