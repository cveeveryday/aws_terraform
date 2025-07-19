# Network Hub Module
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Network Hub VPC
resource "aws_vpc" "network_hub" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(var.common_tags, {
    Name = "${var.organization}-network-hub-${var.environment}-${var.region}"
    Type = "NetworkHub"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "network_hub" {
  vpc_id = aws_vpc.network_hub.id
  
  tags = merge(var.common_tags, {
    Name = "${var.organization}-network-hub-igw-${var.environment}"
  })
}

# Transit Gateway
resource "aws_ec2_transit_gateway" "main" {
  amazon_side_asn                 = var.transit_gateway_config.amazon_side_asn
  auto_accept_shared_attachments  = var.transit_gateway_config.enable_auto_accept_shared_attachments ? "enable" : "disable"
  default_route_table_association = var.transit_gateway_config.enable_default_route_table_association ? "enable" : "disable"
  default_route_table_propagation = var.transit_gateway_config.enable_default_route_table_propagation ? "enable" : "disable"
  
  tags = merge(var.common_tags, {
    Name = "${var.organization}-tgw-${var.environment}-${var.region}"
  })
}

# VPN Gateway (conditional)
resource "aws_vpn_gateway" "main" {
  count  = var.enable_vpn_gateway ? 1 : 0
  vpc_id = aws_vpc.network_hub.id
  
  tags = merge(var.common_tags, {
    Name = "${var.organization}-vpn-gw-${var.environment}"
  })
}

# Cross-region peering (conditional)
resource "aws_ec2_transit_gateway_peering_attachment" "cross_region" {
  count = var.peer_transit_gateway_id != null ? 1 : 0
  
  peer_account_id         = data.aws_caller_identity.current.account_id
  peer_region            = var.peer_transit_gateway_region
  peer_transit_gateway_id = var.peer_transit_gateway_id
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
  
  tags = merge(var.common_tags, {
    Name = "${var.organization}-tgw-peer-${var.environment}"
  })
}
