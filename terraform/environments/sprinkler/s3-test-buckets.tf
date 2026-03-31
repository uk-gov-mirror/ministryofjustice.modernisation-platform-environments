resource "random_id" "s3_test_suffix" {
  byte_length = 4
}

locals {
  s3_test_bucket_suffix = random_id.s3_test_suffix.hex
}

##################################
### Test S3 bucket (non-public)
##################################

resource "aws_s3_bucket" "test_non_public" {
  #checkov:skip=CKV_AWS_18: Access logging not required for sprinkler test bucket
  #checkov:skip=CKV_AWS_145: SSE-KMS not required for sprinkler test bucket
  #checkov:skip=CKV2_AWS_61: Lifecycle configuration not required for sprinkler test bucket
  #checkov:skip=CKV2_AWS_62: Event notifications not required for sprinkler test bucket
  #trivy:ignore:AVD-AWS-0132 reason: SSE-KMS not required for sprinkler test bucket
  bucket        = "${local.application_name}-test-non-public-${data.aws_caller_identity.current.account_id}-${local.s3_test_bucket_suffix}"
  force_destroy = true
  tags          = local.tags
}

resource "aws_s3_bucket_public_access_block" "test_non_public" {
  bucket                  = aws_s3_bucket.test_non_public.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "test_non_public" {
  bucket = aws_s3_bucket.test_non_public.id

  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "test_non_public" {
  bucket = aws_s3_bucket.test_non_public.id
  acl    = "private"
  depends_on = [
    aws_s3_bucket_ownership_controls.test_non_public
  ]
}

resource "aws_s3_bucket_versioning" "test_non_public" {
  bucket = aws_s3_bucket.test_non_public.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "test_non_public" {
  bucket = aws_s3_bucket.test_non_public.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "test_non_public_bucket_policy" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = [
      aws_s3_bucket.test_non_public.arn,
      "${aws_s3_bucket.test_non_public.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "test_non_public" {
  bucket = aws_s3_bucket.test_non_public.id
  policy = data.aws_iam_policy_document.test_non_public_bucket_policy.json
}

##################################
### Test S3 bucket (public)
##################################

# This bucket intentionally demonstrates public access for validation/testing.
#trivy:ignore:AVD-AWS-0132 reason: SSE-KMS not required for sprinkler test bucket
#trivy:ignore:AVD-AWS-0086 reason: Public access is intentional for sprinkler testing
#trivy:ignore:AVD-AWS-0087 reason: Public access is intentional for sprinkler testing
#trivy:ignore:AVD-AWS-0091 reason: Public access is intentional for sprinkler testing
#trivy:ignore:AVD-AWS-0093 reason: Public access is intentional for sprinkler testing
resource "aws_s3_bucket" "test_public" {
  #checkov:skip=CKV_AWS_20: Public access is intentional for sprinkler testing
  #checkov:skip=CKV_AWS_57: Public access is intentional for sprinkler testing
  #checkov:skip=CKV_AWS_18: Access logging not required for sprinkler test bucket
  #checkov:skip=CKV_AWS_145: SSE-KMS not required for sprinkler test bucket
  #checkov:skip=CKV2_AWS_61: Lifecycle configuration not required for sprinkler test bucket
  #checkov:skip=CKV2_AWS_62: Event notifications not required for sprinkler test bucket
  bucket        = "${local.application_name}-test-public-${data.aws_caller_identity.current.account_id}-${local.s3_test_bucket_suffix}"
  force_destroy = true
  tags          = local.tags
}

resource "aws_s3_bucket_public_access_block" "test_public" {
  bucket                  = aws_s3_bucket.test_public.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "test_public" {
  bucket = aws_s3_bucket.test_public.id

  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "test_public" {
  bucket = aws_s3_bucket.test_public.id
  acl    = "public-read"
  depends_on = [
    aws_s3_bucket_ownership_controls.test_public,
    aws_s3_bucket_public_access_block.test_public,
  ]
}

resource "aws_s3_bucket_versioning" "test_public" {
  bucket = aws_s3_bucket.test_public.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "test_public" {
  bucket = aws_s3_bucket.test_public.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "test_public_bucket_policy" {
  statement {
    sid     = "AllowPublicReadForPrefix"
    effect  = "Allow"
    actions = ["s3:GetObject"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = [
      "${aws_s3_bucket.test_public.arn}/public/*",
    ]
  }

  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = [
      aws_s3_bucket.test_public.arn,
      "${aws_s3_bucket.test_public.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "test_public" {
  bucket = aws_s3_bucket.test_public.id
  policy = data.aws_iam_policy_document.test_public_bucket_policy.json
}
