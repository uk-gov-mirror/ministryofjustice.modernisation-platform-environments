# ECS Task Execution Role

data "aws_iam_policy_document" "barclaycard_ecs_task_execution_assume_role_policy" {
  version = "2012-10-17"
  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"
      identifiers = [
        "ecs-tasks.amazonaws.com",
      ]
    }
  }
}

# ECS task execution role
resource "aws_iam_role" "barclaycard_ecs_task_execution_role" {
  name               = "${local.application_name}-barclaycard-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.barclaycard_ecs_task_execution_assume_role_policy.json

  tags = merge(local.tags,
    { Name = lower(format("%s-sftp-barclaycard-%s-ecs-role", local.application_name, local.environment)) }
  )
}

# ECS task execution role policy attachment
resource "aws_iam_role_policy_attachment" "barclaycard_ecs_task_execution_role" {
  role       = aws_iam_role.barclaycard_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Secrets Manager Policy
resource "aws_iam_policy" "barclaycard_ecs_secrets_policy" {
  name = "${local.application_name}-barclaycard-ecs_secrets_policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["secretsmanager:GetSecretValue"],
      "Resource": ["arn:aws:secretsmanager:eu-west-2:*:secret:*"]
    }
  ]
}
EOF
}

# ECS secrets role policy attachment

resource "aws_iam_role_policy_attachment" "barclaycard_ecs_secrets_policy_attachment" {
  role       = aws_iam_role.barclaycard_ecs_task_execution_role.name
  policy_arn = aws_iam_policy.barclaycard_ecs_secrets_policy.arn
}
