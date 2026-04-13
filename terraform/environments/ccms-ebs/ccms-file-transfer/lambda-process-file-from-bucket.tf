
resource "aws_iam_role" "lambda_process_file_from_bucket_role" {
  name = "${local.application_name}-${local.environment}-lambda_process_file_from_bucket_role"

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
    Name = "${local.application_name}-${local.environment}-lambda_process_file_from_bucket_role"
  })
}

resource "aws_iam_role_policy" "lambda_process_file_from_bucket_policy" {
  name = "${local.application_name}-${local.environment}-lambda_process_file_from_bucket_policy"
  role = aws_iam_role.lambda_process_file_from_bucket_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:PutObjectVersionAcl",
          "s3:PutObjectVersionTagging"
        ]
        Resource = [
          module.s3-bucket-sftp-barclaycard.bucket.arn,
          "${module.s3-bucket-sftp-barclaycard.bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.process_file_from_bucket_lambda_function.function_name}:*"
      }
      #   {
      #     Effect = "Allow"
      #     Action = [
      #       "kms:GenerateDataKey*",
      #       "kms:Decrypt"
      #     ]
      #     Resource = [aws_kms_key.cloudwatch_sns_alerts_key.arn]
      #   }
    ]
  })
}

# data "archive_file" "lambda_zip" {
#   type        = "zip"
#   source_dir  = "${path.module}/lambda/process_file_from_bucket"
#   output_path = "${path.module}/lambda/process_file_from_bucket.zip"
# }

# resource "null_resource" "build_lambda" {
#   triggers = {
#     source_hash = filesha256("./lambda/process_file_from_bucket/pom.xml")
#   }

#   provisioner "local-exec" {
#     command = "cd ./lambda/process_file_from_bucket && mvn clean package"
#   }
# }

resource "aws_lambda_function" "process_file_from_bucket_lambda_function" {
  filename         = "./lambda/process_file_from_bucket/target/HelloWorldHandler-1.0.jar"
  # source_code_hash = base64sha256(join("", local.lambda_source_hashes_process_file_from_bucket))
  function_name    = "${local.application_name}-${local.environment}-process-file-from-bucket-lambda-function"
  role             = aws_iam_role.lambda_process_file_from_bucket_role.arn
  handler          = "example.HelloWorldHandler"
  #   layers           = [aws_lambda_layer_version.lambda_cloudwatch_sns_layer.arn]
  runtime = "java21"
  timeout = 30
  publish = true

  #   environment {
  #     variables = {
  #       # This secret now contains slack_channel_webhook, slack_channel_webhook_guardduty, slack_channel_webhook_s3
  #       SECRET_NAME = aws_secretsmanager_secret.ebs_cw_alerts_secrets.name
  # #     }
  #   }

  # depends_on = [null_resource.build_lambda]

  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-process-file-from-bucket"
  })
}

resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_file_from_bucket_lambda_function.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3-bucket-sftp-barclaycard.bucket.arn
}
