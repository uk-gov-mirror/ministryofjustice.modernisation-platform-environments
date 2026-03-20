module "secrets_kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.0"

  aliases                 = ["${local.application_name}-secrets"]
  description             = "KMS key for ${local.application_name} secrets"
  enable_default_policy   = true
  deletion_window_in_days = 7
  tags                    = local.tags
}

resource "aws_kms_key_policy" "key_policy" {
  key_id = module.secrets_kms.key_id
  policy = jsonencode({
    Id = "example"
    Statement = [
      {
        "Sid": "Allow use of the key for SSM only",
        "Effect": "Allow",
        "Principal": {
            "AWS": "arn:aws:iam::754256621582:root"
        },
        "Action": [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*"
        ],
        "Resource": "*",
        "Condition": {
            "StringLike": {
                "kms:ViaService": [
                    "secretsmanager.*.amazonaws.com",
                    "autoscaling.*.amazonaws.com"
                ]
            }
        }
    },
    {
        "Sid": "Allow reading of key metadata",
        "Effect": "Allow",
        "Principal": {
            "AWS": "arn:aws:iam::754256621582:root"
        },
        "Action": "kms:DescribeKey",
        "Resource": "*"
    },
    {
        "Sid": "Allow attachment of persistent resources",
        "Effect": "Allow",
        "Principal": {
            "AWS": "arn:aws:iam::754256621582:root"
        },
        "Action": [
            "kms:CreateGrant",
            "kms:ListGrants",
            "kms:RevokeGrant"
        ],
        "Resource": "*"
    }
    ]
    Version = "2012-10-17"
  })
}