locals {
  ears_sars = "ears_sars"
  ears_sars_cloudtrail = "ears_sars_cloudtrail"
}

# resource "aws_cloudwatch_log_group" "ears_sars_cloudtrail" {
#   name = local.ears_sars_cloudtrail
# }

# resource "aws_cloudtrail" "ears_sars_cloudtrail" {
#   count = local.is-development || local.is-preproduction ? 1 : 0

#   depends_on = [module.s3-logging-bucket.bucket_policy]

#   name                          = local.ears_sars_cloudtrail
#   s3_bucket_name                = module.s3-logging-bucket.bucket.id
#   s3_key_prefix                 = local.ears_sars
#   include_global_service_events = false

#   # Target the State Machine
#   advanced_event_selector {
#     name = "Log ears & sars requests"

#     field_selector {
#       field  = "eventCategory"
#       equals = ["Data"]
#     }

#     # field_selector {
#     #   field  = "eventNames"
#     #   equals = ["StartExecution"]
#     # }

#     field_selector {
#       field  = "resources.type"
#       equals = ["AWS::StepFunctions::StateMachine"]
#     }
    
#     field_selector {
#       field  = "resources.ARN"
#       equals = [module.ears_sars_step_function[0].arn]
#     }
#   }

#   tags = merge(
#     local.tags,
#     {
#       Resource_Type = "CloudTrail resource for EARs/SARs API request Step Function logs",
#     }
#   )
# }


resource "aws_cloudtrail" "ears_sars_cloudtrail" {
  count = local.is-development || local.is-preproduction ? 1 : 0

  depends_on = [module.s3-logging-bucket.bucket_policy]

  name                          = local.ears_sars_cloudtrail
  s3_bucket_name                = module.s3-logging-bucket.bucket.id
  s3_key_prefix                 = local.ears_sars
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
      starts_with = ["${module.s3-logging-bucket.arn}/ears_sars/"]
    }
  }

  tags = merge(
    local.tags,
    {
      Resource_Type = "CloudTrail for EARS&SARS S3 Audit Logs",
    }
  )
}

# data "aws_iam_policy_document" "cloudtrail_policies" {
#   statement {
#     sid       = "TestAPAirflowPermissionsListBuckets"
#     effect    = "Allow"
#     actions   = [
#         "cloudtrail:StartLogging",
#         "cloudtrail:StopLogging",
#         "cloudtrail:GetTrail",
#         "cloudtrail:GetTrailStatus",
#         "cloudtrail:GetEventSelectors"
#         ]
#     resources = ["arn:aws:cloudtrail:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:trail/${local.ears_sars_cloudtrail}"]
#   }
# }
