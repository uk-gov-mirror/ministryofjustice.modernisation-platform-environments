resource "aws_iam_role" "eventbridge_scheduler" {
  name = "${var.project_name}-eventbridge-scheduler"

  assume_role_policy = jsondecode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "scheduler.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "eventbridge_scheduler_lambda" {
  name = "${var.project_name}-invoke-lambda"
  policy = jsondecode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"
      Action = [
        "lambda:InvokeFunction"
      ]
      Resource = aws_lambda_function.github_workflow_trigger.arn
    }]
  })
  role = aws_iam_role.eventbridge_scheduler.id
}

resource "aws_iam_role_policy" "lambda_secrets_manager" {
  name = "${var.project_name}-secrets-manager"
  policy = jsondecode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Resource = aws_secretsmanager_secret.github_app.arn
    }]
  })
  role = aws_iam_role.lambda.id
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  rolepolicy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role           = aws_iam_role.lambda.name
}
