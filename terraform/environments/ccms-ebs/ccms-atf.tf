data "aws_iam_policy_document" "atf_kms_policy" {
  statement {
    sid = "AllowRootAccountAdmin"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
  statement {
    sid = "AllowUseForSecretsManagerInThisAccount"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*"
      , "kms:DescribeKey"
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${data.aws_region.current.name}.amazonaws.com"]
    }
  }
}

resource "aws_kms_key" "atf_kms" {
  count               = local.is_development ? 1 : 0
  description         = "KMS for SSH private keys in Secrets Manager for AWS Transfer Family"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.atf_kms_policy.json
  tags                = { Environment = local.environment }
}

# Generate SSH key pair
resource "tls_private_key" "atf" {
  count     = local.is_development ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "atf" {
  count      = local.is_development ? 1 : 0
  key_name   = "atf_key_name_user1"
  public_key = tls_private_key.atf[0].public_key_openssh
  tags       = { Name = "atf-key", Environment = local.environment }

  lifecycle {
    ignore_changes = [public_key]
  }

}

resource "aws_secretsmanager_secret" "atf_ftp_server_secrets" {
  count                   = local.is_development ? 1 : 0
  name                    = "aws/transfer/${aws_transfer_server.atf_ftp_server.id}/user1"
  kms_key_id              = aws_kms_key.atf_kms[0].arn
  recovery_window_in_days = 7
  tags                    = { Environment = local.environment, Purpose = "sftp-login" }

}

resource "random_password" "password_user1" {
  length  = 16
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
} 

resource "aws_secretsmanager_secret_version" "atf_privkey_v1" {
  count     = local.is_development ? 1 : 0
  secret_id = aws_secretsmanager_secret.atf_ftp_server_secrets.id
  secret_string = jsonencode({
    "atf_user1_username"        = "user1",
    "atf_user1_password"        = random_password.password_user1.result,
    "atf_user1_private_key_pem" = tls_private_key.atf[0].private_key_pem,
    "atf_user1_public_key"      = tls_private_key.atf[0].public_key_openssh,
    # atf_ingerprint_md5 = tls_private_key.atf[0].public_key_fingerprint_md5
    # key_type        = "rsa"
    "atf_user1_key_name"        = aws_key_pair.atf[0].key_name,
    "atf_user1_home_directory"  = aws_s3_bucket.buckets["laa-ccms-inbound-${local.environment}-mp"].id/CCMS_PRD_Barclaycard/Inbound,
    "atf_user1_role"            = aws_iam_role.lambda_atf_ftp_server_role,
    "atf_user1_created_at_utc"  = timestamp(),
    "servername"                = aws_transfer_server.atf_ftp_server.id
  })

#   lifecycle {
#     ignore_changes = [secret_string]
#   }
}

resource "aws_security_group" "atf_ftp_server_sg" {
  name   = "atf-sftp-server-sg"
  vpc_id = aws_vpc.main.id
  tags   = merge(local.tags, { Name = lower(format("sg-%s-%s-atf-ftp-server", local.application_name, local.environment) ) })
}

resource "aws_security_group_ingress_rule" "atf_ftp_server_sg_ingress" {
  security_group_id = aws_security_group.atf_ftp_server_sg.id
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  referenced_security_group_id = aws_security_group.ec2_sg_ebsapps.id
}

resource "aws_security_group_egress_rule" "atf_ftp_server_sg_egress" {
  security_group_id = aws_security_group.atf_ftp_server_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_iam_role" "lambda_atf_ftp_server_role" {
  name = "${local.application_name}-${local.environment}-lambda_atf_ftp_server_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-lambda_atf_ftp_server_role"
  })
}

resource "aws_iam_role_policy" "lambda_atf_ftp_server_role_policy" {
  name = "${local.application_name}-${local.environment}-lambda_atf_ftp_server_role_policy"
  role = aws_iam_role.lambda_atf_ftp_server_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ]
        # Secret now contains slack_channel_webhook, slack_channel_webhook_guardduty, slack_channel_webhook_s3
        Resource = [aws_secretsmanager_secret.ebs_cw_alerts_secrets.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.cloudwatch_sns.function_name}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Resource = [aws_kms_key.atf_kms.arn]
      }
    ]
  })
}

data "archive_file" "atf_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/atf_ftp_server_idp"
  output_path = "${path.module}/lambda/atf_ftp_server_idp.zip"
}

resource "aws_lambda_function" "atf_ftp_server_idp" {
  function_name    = "${local.application_name}-${local.environment}-atf-ftp-server-idp"
  filename         = data.archive_file.atf_lambda_zip.output_path
  source_code_hash = base64sha256(join("", local.lambda_source_hashes_atf_ftp_server_idp))
  role             = aws_iam_role.lambda_atf_ftp_server_role.arn
  handler          = "lambda_function.lambda_handler"
#   layers           = [aws_lambda_layer_version.lambda_cloudwatch_sns_layer.arn]
  runtime          = "python3.13"
  timeout          = 30
  publish          = true

  environment {
    variables = {
      # This secret now contains multiple secrets
      SECRET_NAME = aws_secretsmanager_secret.atf_ftp_server_secrets.name
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-atf-ftp-server-idp"
  })
 
}

resource "aws_iam_role" "atf_ftp_server_user_role" {
  name = "atf-ftp-server-user-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "transfer.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "atf_ftp_server_policy" {
  role = aws_iam_role.atf_ftp_server_user_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = "arn:aws:s3:::${aws_s3_bucket.buckets["laa-ccms-inbound-${local.environment}-mp"].id}"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::${aws_s3_bucket.buckets["laa-ccms-inbound-${local.environment}-mp"].id}/CCMS_PRD_Barclaycard/Inbound/*"
      }
    ]
  })
}

resource "aws_transfer_server" "atf_ftp_server" {
  identity_provider_type = "AWS_LAMBDA"
  function               = aws_lambda_function.atf_ftp_server_idp.arn
  protocols              = ["SFTP"]
  endpoint_type          = "VPC"
  domain                 = "S3"

  endpoint_details {
    vpc_id             = data.aws_vpc.shared.id
    subnet_ids         = data.aws_subnets.shared-private.ids
    security_group_ids = [aws_security_group.atf_ftp_server_sg.id]
  }
}
