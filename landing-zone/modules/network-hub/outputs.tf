data "aws_caller_identity" "current" {}

# Outputs
output "transit_gateway_id" {
  description = "Transit Gateway ID"
  value       = aws_ec2_transit_gateway.main.id
}

output "vpc_id" {
  description = "Network Hub VPC ID"
  value       = aws_vpc.network_hub.id
}
