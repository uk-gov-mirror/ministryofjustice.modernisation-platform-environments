locals {
  cloudtrail_output_prefix = "cloudtrail_logs"
  ears_sars_cloudtrail = "ears_sars_cloudtrail"
}

resource "aws_cloudtrail" "ears_sars_cloudtrail" {
  count = local.is-development || local.is-preproduction ? 1 : 0

  depends_on = [module.s3-logging-bucket.bucket_policy]

  name                          = local.ears_sars_cloudtrail
  s3_bucket_name                = module.s3-logging-bucket.bucket.id
  s3_key_prefix                 = local.cloudtrail_output_prefix
  include_global_service_events = false
  
  advanced_event_selector {
    name = "Log S3 Audit PutEvents"

    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }

    field_selector {
      field  = "resources.type"
      equals = ["AWS::S3::Object"]
    }

    field_selector {
      field  = "readOnly"
      equals = ["false"]
    }
    field_selector {
      field  = "eventName"
      equals = ["PutObject"]
    }

    field_selector {
      field  = "resources.ARN"
      starts_with = ["${module.s3-logging-bucket.bucket.arn}/ears_sars/"]
    }
  }

  tags = merge(
      local.tags,
      {
        Resource_Type = "CloudTrail resource for EARs/SARs API request Step Function logs",
      }
    )
}
