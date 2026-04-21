# SNS Topic for Slack Alerts

resource "aws_sns_topic" "cloudwatch_slack" {
  name              = "cloudwatch-slack-alerts"
  delivery_policy   = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultRequestPolicy": {
      "headerContentType": "text/plain; charset=UTF-8"
    }
  }
}
EOF
  kms_master_key_id = aws_kms_key.cloudwatch_sns_alerts_key.id
  tags = merge(local.tags,
    { Name = "cloudwatch-slack-alerts" }
  )
}

resource "aws_sns_topic_policy" "cloudwatch_slack" {
  arn    = aws_sns_topic.cloudwatch_slack.arn
  policy = data.aws_iam_policy_document.cloudwatch_alerting_sns.json
}

#--Altering SNS
resource "aws_sns_topic" "guardduty_alerts" {
  name              = "${local.application_data.accounts[local.environment].app_name}-guardduty-alerts"
  delivery_policy   = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultRequestPolicy": {
      "headerContentType": "text/plain; charset=UTF-8"
    }
  }
}
EOF
  kms_master_key_id = aws_kms_key.cloudwatch_sns_alerts_key.id
  tags = merge(local.tags,
    { Name = "cloudwatch-slack-alerts" }
  )
}

resource "aws_sns_topic_policy" "guardduty_default" {
  arn    = aws_sns_topic.guardduty_alerts.arn
  policy = data.aws_iam_policy_document.guardduty_alerting_sns.json
}

# RDS minor upgrade notification changes 
# SNS topic for RDS maintenance events

resource "aws_sns_topic" "tds_maintenance_topic" {
  name = "${local.application_name}-${local.environment}-tds-maintenance-topic"
  kms_master_key_id = aws_kms_key.sns_rds_events.arn
  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-tds-maintenance-topic"
  })
}

# SNS Topic policy 

resource "aws_sns_topic_subscription" "rds_to_slack_lambda" {
  topic_arn = aws_sns_topic.tds_maintenance_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.dbmaintenance_sns_to_slack.arn

  depends_on = [
    aws_lambda_permission.allow_rds_sns_invoke
  ]
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/rds_maintenance_notify.py"
  output_path = "${path.module}/lambda/rds_maintenance_notify.zip"
}

resource "aws_lambda_function" "dbmaintenance_sns_to_slack" {
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  function_name    = "${local.application_name}-${local.environment}-rds_maintenance_notify"
  role             = aws_iam_role.lambda_dbmaintenance_sns_role.arn
  handler          = "rds_maintenance_notify.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  publish          = true

  environment {
    variables = {
      SECRET_NAME = aws_secretsmanager_secret.slack_channel_id.name
    }
  }

  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-rds-maintenance-notify"
  })
}

resource "aws_lambda_permission" "allow_rds_sns_invoke" {
  statement_id  = "AllowExecutionFromrdsSNSTopic"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dbmaintenance_sns_to_slack.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.tds
  _maintenance_topic.arn
}
