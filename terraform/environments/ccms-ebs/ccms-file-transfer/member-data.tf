data "aws_sns_topic" "s3_topic" {
  name = "s3-event-notification-topic"
}

data "aws_s3_bucket" "logging_bucket" {
  bucket = "${local.application_name}-${local.environment}-logging"
}