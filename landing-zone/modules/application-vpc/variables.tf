# variables.tf for application-vpc module

variable "application_name" {
  description = "Application name"
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

variable "environment" {
  description = "Environment name"
  type        = string   
}

variable "region" {
  description = "AWS region"
  type        = string   
}


variable "vpc_config" {
  description = "VPC configuration"
  type = object({
    cidr_block           = string
    enable_dns_hostnames = bool
    enable_dns_support   = bool
  })
}

variable "subnet_config" {
  description = "Subnet configuration"
  type = object({
    availability_zones = list(string)
    public_subnets     = bool
    private_subnets    = bool
    database_subnets   = bool
  })
}

variable "transit_gateway_id" {
  description = "Transit Gateway ID to attach to"
  type        = string
}

variable "network_segmentation" {
  description = "Network segmentation rules"
  type = object({
    environment_isolation    = string
    cross_env_communication = bool
  })
}