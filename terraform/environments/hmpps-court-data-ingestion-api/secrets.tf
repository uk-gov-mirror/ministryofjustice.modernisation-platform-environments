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
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecret"
    ]

    resources = ["*"]
  }
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


#software.amazon.awssdk.services.secretsmanager.model.SecretsManagerException: User: arn:aws:sts::754256621582:assumed-role/cloud-platform-irsa-6852dfe05c1167f2-live/aws-sdk-java-1773998691519 is not authorized to perform: secretsmanager:PutSecretValue on resource: arn:aws:secretsmanager:eu-west-2:953751538119:secret:ingestion-api-auth-token-olmeRm because no resource-based policy allows the secretsmanager:PutSecretValue action (Service: SecretsManager, Status Code: 400, Request ID: 238a8219-a4b7-4f1c-8da5-80c93b63c9ec) (SDK Attempt Count: 1)
#["arn:aws:sts::754256621582:assumed-role/cloud-platform-irsa-6852dfe05c1167f2-live/*"]