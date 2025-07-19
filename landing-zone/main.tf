# Root main.tf for AWS Landing Zone

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Example locals for organization-wide tags and settings
locals {
  organization_name = var.organization_name
  environment       = var.environment
  region            = var.region
  cost_center       = var.cost_center
  common_tags = {
    Organization = local.organization_name
    Environment  = local.environment
    CostCenter   = local.cost_center
  }
}

# Network Hub
module "network_hub" {
  source      = "./modules/network-hub"
  environment = local.environment
  region      = local.region
  organization = local.organization_name
  transit_gateway_config = {
    amazon_side_asn                      = 64512
    enable_auto_accept_shared_attachments = true
    enable_default_route_table_association = true
    enable_default_route_table_propagation = true
  }
  enable_vpn_gateway      = false
  enable_dx_gateway       = false
  peer_transit_gateway_id = null
  peer_transit_gateway_region = null
  common_tags             = local.common_tags
}

# Application VPCs (example for web_app and api_service)
module "web_app_vpc" {
  source         = "./modules/application-vpc"
  application_name = var.applications.web_app.name
  common_tags     = local.common_tags
  organization    = local.organization_name
  environment     = local.environment
  region          = local.region
  vpc_config = {
    cidr_block           = var.applications.web_app.vpc_cidr_base
    enable_dns_hostnames = true
    enable_dns_support   = true
  }
  subnet_config = {
    availability_zones = ["${local.region}a", "${local.region}b"]
    public_subnets     = true
    private_subnets    = true
    database_subnets   = true
  }
  transit_gateway_id = module.network_hub.transit_gateway_id
  network_segmentation = {
    environment_isolation    = local.environment == "prod" ? "strict" : "moderate"
    cross_env_communication  = local.environment == "prod" ? false : true
  }
}

module "api_service_vpc" {
  source         = "./modules/application-vpc"
  application_name = var.applications.api_service.name
  common_tags     = local.common_tags
  organization    = local.organization_name
  environment     = local.environment
  region          = local.region
  vpc_config = {
    cidr_block           = var.applications.api_service.vpc_cidr_base
    enable_dns_hostnames = true
    enable_dns_support   = true
  }
  subnet_config = {
    availability_zones = ["${local.region}a", "${local.region}b"]
    public_subnets     = true
    private_subnets    = true
    database_subnets   = true
  }
  transit_gateway_id = module.network_hub.transit_gateway_id
  network_segmentation = {
    environment_isolation    = local.environment == "prod" ? "strict" : "moderate"
    cross_env_communication  = local.environment == "prod" ? false : true
  }
}

# Identity Management
module "identity" {
  source         = "./modules/identity"
  identity_name  = "central-identity"
  common_tags    = local.common_tags
  organization   = local.organization_name
  organization_name = local.organization_name
  sso_config = {
    enable_sso        = true
    session_duration  = "PT8H"
    identity_store_id = "d-xxxxxxxxxx"
  }
  permission_sets = {
    "Admin" = {
      description      = "Administrator access"
      session_duration = "PT8H"
      managed_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
    }
    "ReadOnly" = {
      description      = "Read only access"
      session_duration = "PT4H"
      managed_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
    }
  }
}

# Automation (CI/CD, Backups)
module "automation" {
  source         = "./modules/automation"
  automation_name = "central-automation"
  common_tags    = local.common_tags
  organization   = local.organization_name
  git_repositories = [
    {
      name        = "web-app"
      description = "Web Application Repository"
    },
    {
      name        = "api-service"
      description = "API Service Repository"
    }
  ]
  pipeline_config = {
    enable_cross_account_deploy = true
    artifact_retention_days     = 30
    enable_approval_stage       = true
  }
  backup_config = {
    enable_point_in_time_recovery = true
    backup_retention_days         = 2555
    enable_cross_region_backup    = true
    backup_region                 = var.secondary_region
  }
}

# Governance (Compliance, Monitoring, Backup Policies)
module "governance" {
  source          = "./modules/governance"
  governance_name = "central-governance"
}

# Example outputs
output "network_hub_vpc_id" {
  value = module.network_hub.vpc_id
}

output "web_app_vpc_id" {
  value = module.web_app_vpc.vpc_id
}

output "api_service_vpc_id" {
  value = module.api_service_vpc.vpc_id
}