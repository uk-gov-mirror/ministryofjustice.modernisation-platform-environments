locals {
  application_name = "developer-experience"
  component_name   = "github-backup"

  environment_management            = jsondecode(data.aws_secretsmanager_secret_version.environment_management.secret_string)
  modernisation_platform_account_id = data.aws_ssm_parameter.modernisation_platform_account_id.value
  global_config                     = yamldecode(file("${path.module}/../configuration/global.yml"))

  is_production = substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-production"
  environment   = trimprefix(terraform.workspace, "${local.application_name}-")

  github_backup_bucket_name = "${local.global_config.s3_bucket_prefix}-${local.environment}-github-backup"

  tags = merge(
    jsondecode(data.http.environments_file.response_body).tags,
    { "is-production" = local.is_production },
    { "environment-name" = terraform.workspace },
    { "source-code" = "https://github.com/ministryofjustice/modernisation-platform-environments" }
  )
}
