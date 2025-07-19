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
