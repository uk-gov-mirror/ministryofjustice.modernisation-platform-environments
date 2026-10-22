data "aws_caller_identity" "original_session" {
  provider = aws.original_session
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_ssm_parameter" "modernisation_platform_account_id" {
  provider = aws.original_session
  name     = "modernisation_platform_account_id"
}

data "aws_secretsmanager_secret" "environment_management" {
  provider = aws.modernisation_platform
  name     = "environment_management"
}

data "aws_secretsmanager_secret_version" "environment_management" {
  provider  = aws.modernisation_platform
  secret_id = data.aws_secretsmanager_secret.environment_management.id
}

data "http" "environments_file" {
  url = "https://raw.githubusercontent.com/ministryofjustice/modernisation-platform/main/environments/${local.application_name}.json"
}
