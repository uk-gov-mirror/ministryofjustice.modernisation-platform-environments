# Required VPC endpoints for SSM in private subnets
locals {
  ssm_endpoints = [
    "com.amazonaws.eu-west-2.ssm",           # SSM
    "com.amazonaws.eu-west-2.ssmmessages",   # Session Manager
    "com.amazonaws.eu-west-2.ec2messages",   # EC2 messages
  ]
}

resource "aws_vpc_endpoint" "ssm_endpoints" {
  for_each = toset(local.ssm_endpoints)

  vpc_id              = data.aws_vpc.shared.id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  subnet_ids          = data.aws_subnet.private_subnets_a.id
  security_group_ids  = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true
}

resource "aws_security_group" "vpce_sg" {
  name   = "ssm-vpce-sg"
  vpc_id  = data.aws_vpc.shared.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
   security_groups = aws_security_group.ec2_sg[*].id 
  }

}