resource "aws_lambda_function" "github_workflow_trigger" {
  function_name = "${var.project_name}-trigger"
  handler       = "handler.lambda_handler"
  memory_size   = var.lambda_memory_size
  role          = aws_iam_role.lambda.arn
  runtime       = var.lambda_runtime
  timeout       = var.lambda_timeout

  filename         = data.archive_file.github_workflow_trigger.output_path
  source_code_hash = data.archive_file.github_workflow_trigger.output_base64sha256

  environment {
    variables = {
      GITHUB_APP_SECRET_ARN  = aws_secretsmanager_secret.github_app.arn
      GITHUB_ORG             = var.github_org
    }
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_basic_execution]
}
