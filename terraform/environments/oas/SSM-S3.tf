
# ============================================================
# S3 Bucket
# ============================================================

resource "aws_s3_bucket" "files_bucket" {
  count         = contains(["preproduction", "development"], local.environment) ? 1 : 0
  bucket_prefix = "${local.application_name}-bucket-to-upload-ec2-files"

  tags = {
    Name        = "${local.application_name}-bucket-to-upload-ec2-files"
  }
}

# Block all public access (EC2 accesses via IAM role, not public URLs)
resource "aws_s3_bucket_public_access_block" "files_bucket" {
  count         = contains(["preproduction", "development"], local.environment) ? 1 : 0
  bucket = aws_s3_bucket.files_bucket[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}



# Enable versioning (optional but recommended)
resource "aws_s3_bucket_versioning" "files_bucket" {
  count         = contains(["preproduction", "development"], local.environment) ? 1 : 0
  bucket = aws_s3_bucket.files_bucket[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "files_bucket" {
  count  = contains(["preproduction", "development"], local.environment) ? 1 : 0
  bucket = aws_s3_bucket.files_bucket[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}





# # ============================================================
# # IAM Role for EC2
# # ============================================================

# # Trust policy — allows EC2 instances to assume this role
# data "aws_iam_policy_document" "ec2_assume_role" {
#   statement {
#     effect  = "Allow"
#     actions = ["sts:AssumeRole"]

#     principals {
#       type        = "Service"
#       identifiers = ["ec2.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_role" "ec2_s3_role" {
#   name               = "ec2-s3-access-role"
#   assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

#   tags = {
#     Environment = var.environment
#   }
# }

# # ============================================================
# # IAM Policy — s3:GetObject + s3:ListBucket on this bucket
# # ============================================================

# data "aws_iam_policy_document" "s3_read_policy" {
#   # s3:ListBucket is a bucket-level action
#   statement {
#     sid     = "AllowListBucket"
#     effect  = "Allow"
#     actions = ["s3:ListBucket"]
#     resources = [
#       aws_s3_bucket.files_bucket.arn
#     ]
#   }

#   # s3:GetObject is an object-level action (requires the /* suffix)
#   statement {
#     sid     = "AllowGetObject"
#     effect  = "Allow"
#     actions = ["s3:GetObject"]
#     resources = [
#       "${aws_s3_bucket.files_bucket.arn}/*"
#     ]
#   }
# }

# resource "aws_iam_policy" "s3_read_policy" {
#   name        = "ec2-s3-read-policy"
#   description = "Grants EC2 instances GetObject and ListBucket on the files bucket"
#   policy      = data.aws_iam_policy_document.s3_read_policy.json
# }

# # Attach the policy to the role
# resource "aws_iam_role_policy_attachment" "ec2_s3_attach" {
#   role       = aws_iam_role.ec2_s3_role.name
#   policy_arn = aws_iam_policy.s3_read_policy.arn
# }

# # ============================================================
# # IAM Instance Profile (required to attach a role to EC2)
# # ============================================================

# resource "aws_iam_instance_profile" "ec2_s3_profile" {
#   name = "ec2-s3-instance-profile"
#   role = aws_iam_role.ec2_s3_role.name
# }

# # ============================================================
# # Outputs
# # ============================================================

# output "bucket_name" {
#   description = "Name of the S3 bucket"
#   value       = aws_s3_bucket.files_bucket.id
# }

# output "bucket_arn" {
#   description = "ARN of the S3 bucket"
#   value       = aws_s3_bucket.files_bucket.arn
# }

# output "iam_role_arn" {
#   description = "ARN of the IAM role to attach to EC2"
#   value       = aws_iam_role.ec2_s3_role.arn
# }

# output "instance_profile_name" {
#   description = "Instance profile name — use this when launching EC2 instances"
#   value       = aws_iam_instance_profile.ec2_s3_profile.name
# }
