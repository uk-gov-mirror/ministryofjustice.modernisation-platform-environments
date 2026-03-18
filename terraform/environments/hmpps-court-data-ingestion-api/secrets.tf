#### This file can be used to store secrets specific to the member account ####

module "secret_cloud_platform_account_id" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  name        = "cloud-platform-account-id"
  description = "The AWS Account ID for the Cloud Platform environment corresponding to this environment. Populate manually."
  kms_key_id  = module.secrets_kms.key_id

  ignore_secret_changes = true
  secret_string         = "populate-manually"

  tags = local.tags
}

module "secret_ingestion_api_auth_token" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  name        = "ingestion-api-auth-token"
  description = "Shared secret/token used by the Lambda Authorizer to verify incoming requests. Populate manually."
  kms_key_id  = module.secrets_kms.key_id

  ignore_secret_changes = true
  secret_string         = "populate-manually"

  tags = local.tags

  policy_statements = {
    read = {
      sid = "AllowCPApplicationToReadAndSet"
      principals = [{
        type        = "AWS"
        identifiers = ["arn:aws:sts::754256621582:assumed-role/cloud-platform-irsa-6852dfe05c1167f2-live/aws-sdk-java-1773843258205"]
      }]
      actions   = ["secretsmanager:GetSecretValue", "secretsmanager:PutSecretValue"]
      resources = ["*"]
    }
  }
}
