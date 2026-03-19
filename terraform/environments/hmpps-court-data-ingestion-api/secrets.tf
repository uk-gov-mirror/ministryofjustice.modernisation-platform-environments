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
}

data "aws_iam_policy_document" "secret_ingestion_api_auth_token_policy_data" {
  statement {
    sid    = "AllowCrossAccountAccess"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::754256621582:role/cloud-platform-irsa-6852dfe05c1167f2-live"
      ]
    }

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue"
    ]

    resources = ["*"]
  }
}
data "aws_iam_policy_document" "secret_ingestion_api_auth_token_policy_allow_self_admin_data" {
  statement {
    sid    = "AllowSelfAdmin"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::953751538119:root"
      ]
    }

    actions = [
      "*"
    ]

    resources = ["*"]
  }
}

resource "aws_secretsmanager_secret_policy" "secret_ingestion_api_auth_token_policy" {
  secret_arn = module.secret_ingestion_api_auth_token.secret_arn
  policy     = data.aws_iam_policy_document.secret_ingestion_api_auth_token_policy_data.json
}

resource "aws_secretsmanager_secret_policy" "secret_ingestion_api_auth_token_allow_self_admin_policy" {
  secret_arn = module.secret_ingestion_api_auth_token.secret_arn
  policy     = data.aws_iam_policy_document.secret_ingestion_api_auth_token_policy_allow_self_admin_data.json
}


#["arn:aws:sts::754256621582:assumed-role/cloud-platform-irsa-6852dfe05c1167f2-live/*"]