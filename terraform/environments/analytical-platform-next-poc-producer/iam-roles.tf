module "glue_crawler_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.2.1"

  name = "glue-crawler"

  trust_policy_permissions = {
    TrustedRoleAndServicesToAssume = {
      actions = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      principals = [{
        type        = "Service"
        identifiers = ["glue.amazonaws.com"]
      }]
    }
  }

  policies = {
    aws_glue_service_role = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole",
    glue_crawler          = module.glue_crawler_iam_policy.arn
  }
}

module "airflow_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "6.4.0"

  name = "producer-airflow"

  oidc_providers = {
    ap_compute = {
      provider_arn               = aws_iam_openid_connect_provider.analytical_platform_compute.arn
      namespace_service_accounts = ["mwaa:producer-workflow"]
    }
  }

  create_inline_policy = true
  inline_policy_permissions = {
    AthenaAccess = {
      effect = "Allow"
      actions = [
        "athena:StartQueryExecution",
        "athena:GetQueryExecution",
        "athena:GetQueryResults",
        "athena:StopQueryExecution",
        "athena:ListQueryExecutions",
        "athena:GetWorkGroup",
        "athena:ListWorkGroups"
      ]
      resources = ["*"]
    }
    S3Access = {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:GetObjectAttributes",
        "s3:GetObjectVersion",
        "s3:ListBucket"
      ]
      resources = [
        module.mojap_next_poc_athena_query_s3_bucket.bucket_arn,
        "${module.mojap_next_poc_athena_query_s3_bucket.bucket_arn}/*"
      ]
    }
    GlueAccess = {
      effect = "Allow"
      actions = [
        "glue:GetTable",
        "glue:GetDatabase",
        "glue:GetDatabases",
        "glue:CreateTable",
        "glue:DeleteTable",
        "glue:CreateDatabase",
        "glue:DeleteDatabase",
        "glue:UpdateTable",
        "glue:GetPartition",
        "glue:GetPartitions",
        "glue:GetCatalog"
      ]
      resources = ["*"]
    }
  }
}
