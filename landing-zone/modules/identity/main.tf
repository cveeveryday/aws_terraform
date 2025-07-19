# SSO Instance
resource "aws_ssoadmin_instance" "main" {
  count = var.sso_config.enable_sso ? 1 : 0
  
  tags = var.common_tags
}

# Permission Sets
resource "aws_ssoadmin_permission_set" "sets" {
  for_each = var.permission_sets
  
  name             = each.key
  description      = each.value.description
  instance_arn     = aws_ssoadmin_instance.main[0].arn
  session_duration = each.value.session_duration
  
  tags = var.common_tags
}

# Attach managed policies to permission sets
resource "aws_ssoadmin_managed_policy_attachment" "sets" {
  for_each = {
    for combo in flatten([
      for ps_name, ps_config in var.permission_sets : [
        for policy_arn in ps_config.managed_policies : {
          permission_set = ps_name
          policy_arn    = policy_arn
        }
      ]
    ]) : "${combo.permission_set}-${combo.policy_arn}" => combo
  }
  
  instance_arn       = aws_ssoadmin_instance.main[0].arn
  managed_policy_arn = each.value.policy_arn
  permission_set_arn = aws_ssoadmin_permission_set.sets[each.value.permission_set].arn
}

