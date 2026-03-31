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

module "secret_ingestion_api_auth_token_dev" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  name        = "ingestion-api-auth-token-dev"
  description = "Shared secret/token used by the Lambda Authorizer to verify incoming development requests. Populate manually."
  kms_key_id  = module.secrets_kms.key_id

  ignore_secret_changes = true
  secret_string         = "populate-manually"

  tags = local.tags
}

module "secret_ingestion_api_auth_token_preprod" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  name        = "ingestion-api-auth-token-preprod"
  description = "Shared secret/token used by the Lambda Authorizer to verify incoming preprod requests. Populate manually."
  kms_key_id  = module.secrets_kms.key_id

  ignore_secret_changes = true
  secret_string         = "populate-manually"

  tags = local.tags
}
module "secret_ingestion_api_auth_token_prod" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  name        = "ingestion-api-auth-token-prod"
  description = "Shared secret/token used by the Lambda Authorizer to verify incoming production requests. Populate manually."
  kms_key_id  = module.secrets_kms.key_id

  ignore_secret_changes = true
  secret_string         = "populate-manually"

  tags = local.tags
}