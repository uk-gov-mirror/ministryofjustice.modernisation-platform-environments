# ECS Cluster

resource "aws_ecs_cluster" "main" {
  name = "${local.application_name}-sftp-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# resource "aws_ecs_cluster_capacity_providers" "main" {
#   cluster_name       = aws_ecs_cluster.main.name
#   capacity_providers = [aws_ecs_capacity_provider.capacity-provider.name]
# }

# ECS Task Definition


resource "aws_ecs_task_definition" "ftp_barclaycard" {
  family             = "${local.application_name}-ftp-barclaycard-task"
  execution_role_arn = aws_iam_role.barclaycard_ecs_task_execution_role.arn
  network_mode       = "awsvpc"
  requires_compatibilities = [
    "FARGATE",
  ]
  cpu    = local.application_data.accounts[local.environment].container_cpu
  memory = local.application_data.accounts[local.environment].container_memory

  container_definitions = templatefile(
    "${path.module}/templates/task_definition_api.json.tpl",
    {
      app_name                                                      = local.application_name
      app_image                                                     = local.application_data.accounts[local.environment].app_image
      api_server_port                                               = local.application_data.accounts[local.environment].api_server_port
      aws_region                                                    = local.application_data.accounts[local.environment].aws_region
      container_version                                             = local.application_data.accounts[local.environment].container_version
      ccms_s3_bucket                                                = local.application_data.accounts[local.environment].sftp_barclaycard_bucket
      ebs_db_username                                               = "${aws_secretsmanager_secret.sftp_barclaycard_secrets.arn}:ebs_db_username::"
      ebs_db_password                                               = "${aws_secretsmanager_secret.sftp_barclaycard_secrets.arn}:ebs_db_password::"
      ebs_db_endpoint                                               = "${aws_secretsmanager_secret.sftp_barclaycard_secrets.arn}:ebs_db_endpoint::"
      file_transfer_slack_webhook                                   = "${aws_secretsmanager_secret.sftp_barclaycard_secrets.arn}:file_transfer_slack_webhook::"
    }
  )

  tags = merge(local.tags,
    { Name = lower(format("%s-barclaycard-%s-task", local.application_name, local.environment)) }
  )
}

# ECS Service

resource "aws_ecs_service" "ftp_barclaycard" {
  name            = local.application_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.ftp_barclaycard.arn
  desired_count   = local.application_data.accounts[local.environment].app_count
  launch_type     = "FARGATE"

  health_check_grace_period_seconds = 120
  lifecycle {
    ignore_changes = [
      task_definition
    ]
  }
  ordered_placement_strategy {
    field = "attribute:ecs.availability-zone"
    type  = "spread"
  }

  network_configuration {
    security_groups = [aws_security_group.cluster_fargate_sg.id]
    subnets         = data.aws_subnets.shared-private.ids
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.sftp_barclaycard_target_group.arn
    container_name   = local.application_name
    container_port   = local.application_data.accounts[local.environment].api_server_port
  }

  depends_on = [
    aws_lb_listener.sftp_barclaycard_listener,
    aws_iam_role_policy_attachment.barclaycard_ecs_task_execution_role
  ]
}
