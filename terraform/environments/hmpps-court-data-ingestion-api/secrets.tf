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
        "*"
      ]
    }

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue"
    ]

    resources = ["*"]
  }
}

resource "aws_secretsmanager_secret_policy" "secret_ingestion_api_auth_token_policy" {
  secret_arn = module.secret_ingestion_api_auth_token.secret_arn
  policy     = data.aws_iam_policy_document.secret_ingestion_api_auth_token_policy_data.json
}

resource "aws_kms_key" "kms_key_for_secret" {
  description = "KMS key for Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "EnableRootPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::754256621582:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid = "AllowExternalRoleUsage"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:sts::754256621582:assumed-role/cloud-platform-irsa-6852dfe05c1167f2-live"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

#["arn:aws:sts::754256621582:assumed-role/cloud-platform-irsa-6852dfe05c1167f2-live/*"]