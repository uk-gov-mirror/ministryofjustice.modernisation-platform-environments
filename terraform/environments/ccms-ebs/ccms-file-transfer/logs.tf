moved {
  from = aws_cloudwatch_log_group.log_group_sftp_barclaycard
  to   = aws_cloudwatch_log_group.log_group_sftp_bc
}

# Set up CloudWatch group and log stream and retain logs for 90 days
resource "aws_cloudwatch_log_group" "log_group_sftp_bc" {
  name              = "${local.application_name}-sftp-barclaycard-ecs"
  retention_in_days = 90

  tags = merge(local.tags,
    { Name = lower(format("%s-sftp-bc-%s-logs", local.application_name, local.environment)) }
  )
}

moved {
  from = aws_cloudwatch_log_stream.log_stream_sftp_barclaycard
  to   = aws_cloudwatch_log_stream.log_stream_sftp_bc
}

resource "aws_cloudwatch_log_stream" "log_stream_sftp_bc" {
  name           = "${local.application_name}-sftp-bc-log-stream"
  log_group_name = aws_cloudwatch_log_group.log_group_sftp_bc.name
}