##############################################
### Secrets for IAM Identity Center Integration
### 
### No directory service passwords needed when
### using IAM Identity Center as identity source
##############################################

# Store IAM Identity Center configuration for reference
resource "aws_secretsmanager_secret" "identity_center_config" {
  count                   = local.environment == "development" ? 1 : 0
  name                    = "${local.application_name}/${local.environment}/identity-center-config"
  description             = "IAM Identity Center configuration for WorkSpaces - ${local.application_name}-${local.environment}"
  recovery_window_in_days = 7

  tags = merge(
    local.tags,
    {
      "Name"           = "${local.application_name}/${local.environment}/identity-center-config"
      "Purpose"        = "IAMIdentityCenterReference"
      "IdentitySource" = "IAMIdentityCenter"
    }
  )
}

resource "aws_secretsmanager_secret_version" "identity_center_config" {
  count     = local.environment == "development" ? 1 : 0
  secret_id = aws_secretsmanager_secret.identity_center_config[0].id
  secret_string = jsonencode(
    {
      instance_arn    = local.application_data.accounts[local.environment].identity_center_instance_arn
      directory_type  = "IAMIdentityCenter"
      authentication  = "IAMIdentityCenter-SSO"
      description     = "WorkSpaces uses IAM Identity Center for authentication. Users managed in IAM Identity Center."
    }
  )
}
