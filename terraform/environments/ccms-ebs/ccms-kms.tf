resource "aws_kms_key" "oracle_ec2" {
  enable_key_rotation = true

  tags = merge(local.tags,
    { Name = "oracle_ec2" }
  )
}

resource "aws_kms_alias" "oracle_ec2_alias" {
  name          = "alias/ec2_oracle_key"
  target_key_id = aws_kms_key.oracle_ec2.arn
}

resource "aws_kms_key" "shared_s3_cmk" {
  description             = "Shared CMK for S3 buckets (Lambda + GuardDuty Malware Protection)"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = merge(local.tags, {
    Name = "shared-s3-cmk"
  })
}

resource "aws_kms_alias" "shared_s3_cmk" {
  name          = "alias/shared-s3-cmk"
  target_key_id = aws_kms_key.shared_s3_cmk.key_id
}

  