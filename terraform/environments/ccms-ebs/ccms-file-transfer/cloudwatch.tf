#######################################
# CloudWatch Alarms for PUI
#######################################
# Alarm for ALB 5xx Errors
resource "aws_cloudwatch_metric_alarm" "alb_sftp_barclaycard_5xx" {
  alarm_name          = "${local.application_name}-${local.environment}-sftp-barclaycard-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alarm when the number of 5xx errors from the sftp_barclaycard ALB exceeds 10 in a 3 minute period"
  dimensions = {
    LoadBalancer = aws_lb.sftp_barclaycard_load_balancer.arn_suffix
  }
  treat_missing_data = "notBreaching"
  alarm_actions      = [aws_sns_topic.cloudwatch_alerts.arn]
  ok_actions         = [aws_sns_topic.cloudwatch_alerts.arn]

  tags = local.tags
}

# Alarm for ECS Container Count for sftp_barclaycard Service
resource "aws_cloudwatch_metric_alarm" "container_sftp_barclaycard_count" {
  alarm_name          = "${local.application_name}-${local.environment}-sftp-barclaycard-container-count-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Average"
  threshold           = local.application_data.accounts[local.environment].app_count
  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.sftp_barclaycard_ecs_service.name
  }
  alarm_description         = "The number of sftp_barclaycard ECS tasks is less than ${local.application_data.accounts[local.environment].app_count}. Runbook: https://dsdmoj.atlassian.net/wiki/spaces/CCMS/pages/1408598133/Monitoring+and+Alerts"
  treat_missing_data        = "breaching"
  alarm_actions             = [aws_sns_topic.cloudwatch_alerts.arn]
  ok_actions                = [aws_sns_topic.cloudwatch_alerts.arn]
  insufficient_data_actions = []

  tags = local.tags
}

# Underlying waf Instance Status Check Failure
resource "aws_cloudwatch_metric_alarm" "sftp_barclaycard_waf_high_blocked_requests" {
  alarm_name        = "${local.application_name}-sftp-barclaycard-${local.environment}-waf-high-blocked-requests"
  alarm_description = "High number of requests blocked by WAF. Potential attack."

  comparison_operator = "GreaterThanThreshold"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 5
  threshold           = 50 # tune for your workload
  treat_missing_data  = "notBreaching"

  dimensions = {
    WebACL = aws_wafv2_web_acl.sftp_barclaycard_waf.name
    Scope  = "REGIONAL"
  }

  alarm_actions = [aws_sns_topic.cloudwatch_alerts.arn]
  ok_actions    = [aws_sns_topic.cloudwatch_alerts.arn]

  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "sftp_barclaycard_alb_healthyhosts" {
  alarm_name          = "${local.application_name}-sftp-barclaycard-${local.environment}-alb-targets-group"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 240
  statistic           = "Average"
  threshold           = local.application_data.accounts[local.environment].app_count
  alarm_description   = "Number of healthy nodes in Target Group"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.cloudwatch_alerts.arn]
  ok_actions          = [aws_sns_topic.cloudwatch_alerts.arn]
  dimensions = {
    TargetGroup  = aws_lb_target_group.sftp_barclaycard_target_group.arn_suffix
    LoadBalancer = aws_lb.sftp_barclaycard_load_balancer.arn_suffix
  }
}