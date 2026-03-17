##############################################
### Secrets for IAM Identity Center
###
### No secrets needed - IAM Identity Center handles
### all authentication. No directory passwords.
##############################################

# Optional: Store IAM Identity Center configuration for reference
resource "aws_secretsmanager_secret" "iam_identity_center_config" {
  count                   = local.environment == "development" ? 1 : 0
  name                    = "${local.application_name}/${local.environment}/iam-identity-center-config"
  description             = "IAM Identity Center configuration reference for ${local.application_name}-${local.environment}"
  recovery_window_in_days = 7

  tags = merge(
    local.tags,
    {
      "Name"    = "${local.application_name}/${local.environment}/iam-identity-center-config"
      "Purpose" = "IAMIdentityCenter-Reference"
    }
  )
}

resource "aws_secretsmanager_secret_version" "iam_identity_center_config" {
  count     = local.environment == "development" ? 1 : 0
  secret_id = aws_secretsmanager_secret.iam_identity_center_config[0].id
  secret_string = jsonencode({
    instance_arn    = local.application_data.accounts[local.environment].identity_center_instance_arn
    directory_type  = "IAMIdentityCenter"
    authentication  = "IAM-Identity-Center-SSO"
    notes           = "Directory created manually via console and imported to Terraform"
  })
}
