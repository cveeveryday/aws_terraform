# Outputs
output "sso_instance_arn" {
  description = "SSO instance ARN"
  value       = var.sso_config.enable_sso ? aws_ssoadmin_instance.main[0].arn : null
}

output "identity_store_id" {
  description = "Identity store ID"
  value       = var.sso_config.enable_sso ? aws_ssoadmin_instance.main[0].identity_store_id : null
}