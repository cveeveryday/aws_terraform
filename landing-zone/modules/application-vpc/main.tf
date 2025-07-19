# Application VPC
resource "aws_vpc" "application" {
  cidr_block           = var.vpc_config.cidr_block
  enable_dns_hostnames = var.vpc_config.enable_dns_hostnames
  enable_dns_support   = var.vpc_config.enable_dns_support
  
  tags = merge(var.common_tags, {
    Name = "${var.organization}-${var.application_name}-${var.environment}-${var.region}"
    Type = "ApplicationVPC"
  })
}

# Subnets
resource "aws_subnet" "private" {
  count = var.subnet_config.private_subnets ? length(var.subnet_config.availability_zones) : 0
  
  vpc_id            = aws_vpc.application.id
  cidr_block        = cidrsubnet(var.vpc_config.cidr_block, 8, count.index)
  availability_zone = var.subnet_config.availability_zones[count.index]
  
  tags = merge(var.common_tags, {
    Name = "${var.organization}-${var.application_name}-private-${count.index + 1}-${var.environment}"
    Type = "Private"
  })
}

resource "aws_subnet" "public" {
  count = var.subnet_config.public_subnets ? length(var.subnet_config.availability_zones) : 0
  
  vpc_id            = aws_vpc.application.id
  cidr_block        = cidrsubnet(var.vpc_config.cidr_block, 8, count.index + 100)
  availability_zone = var.subnet_config.availability_zones[count.index]
  
  map_public_ip_on_launch = true
  
  tags = merge(var.common_tags, {
    Name = "${var.organization}-${var.application_name}-public-${count.index + 1}-${var.environment}"
    Type = "Public"
  })
}

resource "aws_subnet" "database" {
  count = var.subnet_config.database_subnets ? length(var.subnet_config.availability_zones) : 0
  
  vpc_id            = aws_vpc.application.id
  cidr_block        = cidrsubnet(var.vpc_config.cidr_block, 8, count.index + 200)
  availability_zone = var.subnet_config.availability_zones[count.index]
  
  tags = merge(var.common_tags, {
    Name = "${var.organization}-${var.application_name}-database-${count.index + 1}-${var.environment}"
    Type = "Database"
  })
}

# Transit Gateway VPC Attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "application" {
  subnet_ids         = aws_subnet.private[*].id
  transit_gateway_id = var.transit_gateway_id
  vpc_id            = aws_vpc.application.id
  
  tags = merge(var.common_tags, {
    Name = "${var.organization}-${var.application_name}-tgw-attachment-${var.environment}"
  })
}

# Security Groups with Network Segmentation
resource "aws_security_group" "application_default" {
  name_prefix = "${var.application_name}-default-"
  vpc_id      = aws_vpc.application.id
  
  # Environment-based rules
  dynamic "ingress" {
    for_each = var.network_segmentation.cross_env_communication ? [1] : []
    content {
      description = "Allow cross-environment communication"
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
    }
  }
  
  dynamic "ingress" {
    for_each = var.network_segmentation.environment_isolation == "strict" ? [1] : []
    content {
      description = "Strict environment isolation"
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      cidr_blocks = [var.vpc_config.cidr_block]
    }
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.common_tags, {
    Name = "${var.organization}-${var.application_name}-default-sg-${var.environment}"
  })
}

# Outputs
output "vpc_id" {
  description = "Application VPC ID"
  value       = aws_vpc.application.id
}

output "cidr_block" {
  description = "VPC CIDR block"
  value       = aws_vpc.application.cidr_block
}

output "subnet_ids" {
  description = "Subnet IDs"
  value = {
    private  = aws_subnet.private[*].id
    public   = aws_subnet.public[*].id
    database = aws_subnet.database[*].id
  }
}
