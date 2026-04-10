### Load Balancer Security Group

resource "aws_security_group" "sftp_barclaycard_load_balancer" {
  name_prefix = "${local.application_name}-sftp-barclaycard-load-balancer-sg"
  description = "Controls access to ${local.application_name}-sftp-barclaycard lb"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-sftp-barclaycard-%s-lb-sg", local.application_name, local.environment)) }
  )
}

resource "aws_vpc_security_group_ingress_rule" "sftp_barclaycard_lb_ingress_443" {
  security_group_id = aws_security_group.sftp_barclaycard_load_balancer.id

  cidr_ipv4   = "0.0.0.0/0"
  description = "HTTPS from Anywhere - WAF in front of ALB"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
}

resource "aws_vpc_security_group_egress_rule" "sftp_barclaycard_lb_egress_all" {
  security_group_id = aws_security_group.sftp_barclaycard_load_balancer.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
}

### Container Security Group

# resource "aws_security_group" "ecs_tasks_sftp_barclaycard" {
#   name_prefix = "${local.application_name}-sftp-barclaycard-ecs-tasks-security-group"
#   description = "Controls access to ${local.application_name}-sftp-barclaycard containers"
#   vpc_id      = data.aws_vpc.shared.id

#   tags = merge(local.tags,
#     { Name = lower(format("%s-sftp-barclaycard-%s-task-sg", local.application_name, local.environment)) }
#   )
# }

# resource "aws_vpc_security_group_ingress_rule" "ecs_tasks_sftp_barclaycard" {
#   security_group_id            = aws_security_group.ecs_tasks_sftp_barclaycard.id
#   description                  = "SFTP Client1 ALB into ECS tasks"
#   ip_protocol                  = "tcp"
#   from_port                    = local.application_data.accounts[local.environment].sftp_barclaycard_port
#   to_port                      = local.application_data.accounts[local.environment].sftp_barclaycard_port
#   referenced_security_group_id = aws_security_group.sftp_barclaycard_load_balancer.id
# }

# resource "aws_vpc_security_group_egress_rule" "ecs_tasks_sftp_barclaycard_egress_all" {
#   security_group_id = aws_security_group.ecs_tasks_sftp_barclaycard.id

#   cidr_ipv4   = "0.0.0.0/0"
#   ip_protocol = "tcp"
#   from_port   = 0
#   to_port     = 65535
# }


# Fargate Security Group
resource "aws_security_group" "cluster_fargate_sg" {
  name        = "${local.application_name}-cluster-fargate-security-group"
  description = "Controls access to the cluster fargate tasks"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-fargate-sg", local.application_name, local.environment)) }
  )
}

resource "aws_vpc_security_group_ingress_rule" "cluster_fargate_sg_ingress_all" {
  security_group_id = aws_security_group.cluster_fargate_sg.id

  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].api_server_port
  to_port                      = local.application_data.accounts[local.environment].api_server_port
  referenced_security_group_id = aws_security_group.sftp_barclaycard_load_balancer.id
}

resource "aws_vpc_security_group_egress_rule" "cluster_fargate_sg_egress_all" {
  security_group_id = aws_security_group.cluster_fargate_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
}
