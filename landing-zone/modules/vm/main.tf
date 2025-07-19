# main.tf for AWS EC2 vm module

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data source to get existing VPC
data "aws_vpc" "main" {
  count = var.vpc_id != null ? 1 : 0
  id    = var.vpc_id
}

# Data source to get VPC by name if ID not provided
data "aws_vpc" "main_by_name" {
  count = var.vpc_id == null && var.vpc_name != null ? 1 : 0
  
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

# Data source to get existing subnet
data "aws_subnet" "main" {
  count = var.subnet_id != null ? 1 : 0
  id    = var.subnet_id
}

# Data source to get subnet by name if ID not provided
data "aws_subnet" "main_by_name" {
  count = var.subnet_id == null && var.subnet_name != null ? 1 : 0
  
  filter {
    name   = "tag:Name"
    values = [var.subnet_name]
  }
}

# Data source for AMI
data "aws_ami" "selected" {
  count       = var.ami_id == null ? 1 : 0
  most_recent = true
  owners      = [var.ami_owner]

  filter {
    name   = "name"
    values = [var.ami_name_filter]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group
resource "aws_security_group" "vm_sg" {
  count       = var.create_security_group ? 1 : 0
  name        = "${var.instance_name_prefix}-sg"
  description = "Security group for ${var.instance_name_prefix} instances"
  vpc_id      = local.vpc_id

  dynamic "ingress" {
    for_each = var.security_group_rules.ingress
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  dynamic "egress" {
    for_each = var.security_group_rules.egress
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      description = egress.value.description
    }
  }

  tags = merge(var.tags, {
    Name = "${var.instance_name_prefix}-sg"
  })
}

# Key Pair (if creating new one)
resource "aws_key_pair" "vm_key" {
  count      = var.create_key_pair ? 1 : 0
  key_name   = "${var.instance_name_prefix}-key"
  public_key = var.public_key

  tags = var.tags
}

# EBS volumes for additional storage
resource "aws_ebs_volume" "data_volume" {
  count             = var.enable_data_volume ? var.instance_count : 0
  availability_zone = local.availability_zone
  size              = var.data_volume_size
  type              = var.data_volume_type
  encrypted         = var.data_volume_encrypted
  kms_key_id        = var.data_volume_kms_key_id
  iops              = var.data_volume_type == "gp3" || var.data_volume_type == "io1" || var.data_volume_type == "io2" ? var.data_volume_iops : null
  throughput        = var.data_volume_type == "gp3" ? var.data_volume_throughput : null

  tags = merge(var.tags, {
    Name = "${var.instance_name_prefix}-data-${count.index + 1}"
  })
}

# Elastic IP (if requested)
resource "aws_eip" "vm_eip" {
  count    = var.create_eip ? var.instance_count : 0
  domain   = "vpc"
  instance = aws_instance.vm[count.index].id

  tags = merge(var.tags, {
    Name = "${var.instance_name_prefix}-eip-${count.index + 1}"
  })

  depends_on = [aws_instance.vm]
}

# EC2 Instances
resource "aws_instance" "vm" {
  count           = var.instance_count
  ami             = local.ami_id
  instance_type   = var.instance_type
  key_name        = local.key_name
  subnet_id       = local.subnet_id
  security_groups = var.create_security_group ? [aws_security_group.vm_sg[0].id] : var.existing_security_group_ids
  
  associate_public_ip_address = var.associate_public_ip && !var.create_eip
  private_ip                  = length(var.private_ips) > count.index ? var.private_ips[count.index] : null
  
  user_data                   = var.user_data
  user_data_base64            = var.user_data_base64
  user_data_replace_on_change = var.user_data_replace_on_change

  # Root volume configuration
  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    encrypted             = var.root_volume_encrypted
    kms_key_id            = var.root_volume_kms_key_id
    iops                  = var.root_volume_type == "gp3" || var.root_volume_type == "io1" || var.root_volume_type == "io2" ? var.root_volume_iops : null
    throughput            = var.root_volume_type == "gp3" ? var.root_volume_throughput : null
    delete_on_termination = var.root_volume_delete_on_termination

    tags = merge(var.tags, {
      Name = "${var.instance_name_prefix}-root-${count.index + 1}"
    })
  }

  # Additional EBS volumes (if specified in variable)
  dynamic "ebs_block_device" {
    for_each = var.additional_ebs_volumes
    content {
      device_name           = ebs_block_device.value.device_name
      volume_type           = ebs_block_device.value.volume_type
      volume_size           = ebs_block_device.value.volume_size
      encrypted             = ebs_block_device.value.encrypted
      kms_key_id            = ebs_block_device.value.kms_key_id
      iops                  = ebs_block_device.value.volume_type == "gp3" || ebs_block_device.value.volume_type == "io1" || ebs_block_device.value.volume_type == "io2" ? ebs_block_device.value.iops : null
      throughput            = ebs_block_device.value.volume_type == "gp3" ? ebs_block_device.value.throughput : null
      delete_on_termination = ebs_block_device.value.delete_on_termination

      tags = merge(var.tags, {
        Name = "${var.instance_name_prefix}-${ebs_block_device.value.device_name}-${count.index + 1}"
      })
    }
  }

  iam_instance_profile = var.iam_instance_profile
  
  monitoring                 = var.detailed_monitoring
  disable_api_termination   = var.disable_api_termination
  disable_api_stop          = var.disable_api_stop
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior

  tags = merge(var.tags, {
    Name = "${var.instance_name_prefix}-${count.index + 1}"
  })

  volume_tags = var.enable_volume_tags ? merge(var.tags, {
    Name = "${var.instance_name_prefix}-${count.index + 1}"
  }) : null

  lifecycle {
    ignore_changes = [
      ami,
      user_data,
      user_data_base64
    ]
  }
}

# Attach additional EBS volumes
resource "aws_volume_attachment" "data_volume_attachment" {
  count       = var.enable_data_volume ? var.instance_count : 0
  device_name = var.data_volume_device_name
  volume_id   = aws_ebs_volume.data_volume[count.index].id
  instance_id = aws_instance.vm[count.index].id
}

# Local values for computed attributes
locals {
  vpc_id = var.vpc_id != null ? var.vpc_id : (
    var.vpc_name != null ? data.aws_vpc.main_by_name[0].id : null
  )
  
  subnet_id = var.subnet_id != null ? var.subnet_id : (
    var.subnet_name != null ? data.aws_subnet.main_by_name[0].id : null
  )
  
  availability_zone = var.subnet_id != null ? data.aws_subnet.main[0].availability_zone : (
    var.subnet_name != null ? data.aws_subnet.main_by_name[0].availability_zone : null
  )
  
  ami_id = var.ami_id != null ? var.ami_id : data.aws_ami.selected[0].id
  
  key_name = var.create_key_pair ? aws_key_pair.vm_key[0].key_name : var.existing_key_pair_name
}