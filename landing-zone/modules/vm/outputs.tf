# outputs.tf for AWS EC2 vm module

output "instance_ids" {
  description = "IDs of the EC2 instances"
  value       = aws_instance.vm[*].id
}

output "instance_names" {
  description = "Names of the EC2 instances"
  value       = aws_instance.vm[*].tags.Name
}

output "instance_arns" {
  description = "ARNs of the EC2 instances"
  value       = aws_instance.vm[*].arn
}

output "private_ips" {
  description = "Private IP addresses of the instances"
  value       = aws_instance.vm[*].private_ip
}

output "public_ips" {
  description = "Public IP addresses of the instances (if assigned)"
  value       = aws_instance.vm[*].public_ip
}

output "elastic_ips" {
  description = "Elastic IP addresses (if created)"
  value       = var.create_eip ? aws_eip.vm_eip[*].public_ip : []
}

output "instance_public_dns" {
  description = "Public DNS names of the instances"
  value       = aws_instance.vm[*].public_dns
}

output "instance_private_dns" {
  description = "Private DNS names of the instances"
  value       = aws_instance.vm[*].private_dns
}

output "security_group_id" {
  description = "ID of the created security group (if created)"
  value       = var.create_security_group ? aws_security_group.vm_sg[0].id : null
}

output "key_pair_name" {
  description = "Name of the key pair used"
  value       = local.key_name
}

output "data_volume_ids" {
  description = "IDs of the data volumes (if created)"
  value       = var.enable_data_volume ? aws_ebs_volume.data_volume[*].id : []
}

output "root_volume_ids" {
  description = "IDs of the root volumes"
  value       = aws_instance.vm[*].root_block_device.0.volume_id
}

output "availability_zones" {
  description = "Availability zones of the instances"
  value       = aws_instance.vm[*].availability_zone
}

output "subnet_ids" {
  description = "Subnet IDs of the instances"
  value       = aws_instance.vm[*].subnet_id
}

output "vpc_security_group_ids" {
  description = "VPC security group IDs associated with the instances"
  value       = aws_instance.vm[*].vpc_security_group_ids
}

output "ami_id" {
  description = "AMI ID used for the instances"
  value       = local.ami_id
}

output "instance_state" {
  description = "State of the instances"
  value       = aws_instance.vm[*].instance_state
}

output "instance_details" {
  description = "Detailed information about all instances"
  value = [
    for i, instance in aws_instance.vm : {
      id               = instance.id
      name             = instance.tags.Name
      instance_type    = instance.instance_type
      ami_id           = instance.ami
      availability_zone = instance.availability_zone
      private_ip       = instance.private_ip
      public_ip        = instance.public_ip
      elastic_ip       = var.create_eip ? aws_eip.vm_eip[i].public_ip : null
      public_dns       = instance.public_dns
      private_dns      = instance.private_dns
      subnet_id        = instance.subnet_id
      vpc_id           = instance.vpc_security_group_ids
      key_name         = instance.key_name
      state            = instance.instance_state
      root_volume_id   = instance.root_block_device[0].volume_id
      data_volume_id   = var.enable_data_volume ? aws_ebs_volume.data_volume[i].id : null
    }
  ]
}

output "ssh_connection_commands" {
  description = "SSH connection commands for Linux instances"
  value = [
    for i, instance in aws_instance.vm : 
    "ssh -i ~/.ssh/${local.key_name}.pem ec2-user@${var.create_eip ? aws_eip.vm_eip[i].public_ip : instance.public_ip}"
    if var.create_eip || var.associate_public_ip
  ]
}