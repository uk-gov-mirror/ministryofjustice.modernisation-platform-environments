locals {
  ears_sars = "ears_sars"
  ears_sars_cloudtrail = "ears_sars_cloudtrail"
}

resource "aws_cloudwatch_log_group" "ears_sars_cloudtrail" {
  name = local.ears_sars_cloudtrail
}

resource "aws_cloudtrail" "ears_sars_cloudtrail" {
  count = local.is-development || local.is-preproduction ? 1 : 0

  depends_on = [module.s3-logging-bucket.bucket_policy]

  name                          = local.ears_sars_cloudtrail
  s3_bucket_name                = module.s3-logging-bucket.bucket.id
  s3_key_prefix                 = local.ears_sars
  include_global_service_events = false

  # Target the State Machine
  advanced_event_selector {
    name = "Log ears & sars requests"

    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }

    # field_selector {
    #   field  = "eventNames"
    #   equals = ["StartExecution"]
    # }

    field_selector {
      field  = "resources.type"
      equals = ["AWS::StepFunctions::StateMachine"]
    }
    
    field_selector {
      field  = "resources.ARN"
      equals = [module.ears_sars_step_function[0].arn]
    }
  }

  tags = merge(
    local.tags,
    {
      Resource_Type = "CloudTrail resource for EARs/SARs API request Step Function logs",
    }
  )
}

data "aws_iam_policy_document" "cloudtrail_policies" {
  statement {
    sid       = "TestAPAirflowPermissionsListBuckets"
    effect    = "Allow"
    actions   = [
        "cloudtrail:StartLogging",
        "cloudtrail:StopLogging",
        "cloudtrail:GetTrail",
        "cloudtrail:GetTrailStatus",
        "cloudtrail:GetEventSelectors"
        ]
    resources = ["arn:aws:cloudtrail:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:trail/${local.ears_sars_cloudtrail}"]
  }
}

resource "aws_athena_database" "audit_db" {
  name    = "audit_logs_db"
  comment = "Database for CloudTrail and Security audit logs"

  bucket = module.s3-athena-bucket.bucket.id
  workgroup = aws_athena_workgroup.ears_sars.name

  depends_on = [module.s3-athena-bucket.bucket]
}

resource "aws_glue_catalog_table" "ear_sar_api_cloudtrail_logs" {
  database_name = aws_athena_database.audit_db.name # Assuming you created an Athena DB
  name          = "cloudtrail_targeted_logs"

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "EXTERNAL"                           = "TRUE"
    # Enable Partition Projection
    "projection.enabled"                 = "true"
    
    # Define the timestamp partition (maps to Year/Month/Day folders)
    "projection.timestamp.type"          = "date"
    "projection.timestamp.format"        = "yyyy/MM/dd"
    "projection.timestamp.range"         = "2026/01/01,NOW"
    "projection.timestamp.interval"      = "1"
    "projection.timestamp.interval.unit" = "DAYS"
    
    # Define the region partition
    "projection.region.type"             = "enum"
    "projection.region.values"           = "eu-west-2"
    
    # Provide the exact mathematical template Athena uses to find the files
    "storage.location.template"          = "s3://${module.s3-logging-bucket.bucket.id}/${local.ears_sars}/AWSLogs/${data.aws_caller_identity.current.account_id}/CloudTrail/$${region}/$${timestamp}"
  }

  # Define the partitioning keys
  partition_keys {
    name = "region"
    type = "string"
  }
  partition_keys {
    name = "timestamp"
    type = "string"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.audit_logs.id}/${local.ears_sars}/AWSLogs/${data.aws_caller_identity.current.account_id}/CloudTrail/$${region}/"
    input_format  = "com.amazon.emr.cloudtrail.CloudTrailInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    # Use the specific CloudTrail SerDe to handle the complex JSON
    ser_de_info {
      name                  = "cloudtrail-serde"
      serialization_library = "com.amazon.emr.hive.serde.CloudTrailSerde"
    }

    # Standard CloudTrail columns. 
    # 'requestparameters' is kept as a string so you can use Athena JSON functions to extract specific data based on the API call.
    columns { 
      name = "eventversion"        
      type = "string" 
    }
    columns {
      name = "useridentity"
      type = "struct<type:string,principalid:string,arn:string,accountid:string,invokedby:string,accesskeyid:string,username:string,onbehalfof:struct<userid:string,identitystorearn:string>,sessioncontext:struct<attributes:struct<mfaauthenticated:string,creationdate:string>,sessionissuer:struct<type:string,principalid:string,arn:string,accountid:string,username:string>,ec2roledelivery:string,webidfederationdata:struct<federatedprovider:string,attributes:map<string,string>>>>" 
    }
    columns {
      name = "eventtime"
      type = "string" 
    }
    columns {
      name = "eventsource"
      type = "string" 
    }
    columns {
      name = "eventname"
      type = "string" 
    }
    columns {
      name = "awsregion"
      type = "string" 
    }
    columns {
      name = "sourceipaddress"
      type = "string" 
    }
    columns {
      name = "useragent"
      type = "string" 
    }
    columns {
      name = "errorcode"
      type = "string" 
    }
    columns {
      name = "errormessage"
      type = "string" 
    }
    columns {
      name = "requestparameters"
      type = "string" 
    } # We can think about changing this later as we can query this in Athena.
    columns {
      name = "responseelements"
      type = "string" 
    }
    columns {
      name = "additionaleventdata"
      type = "string" 
    }
    columns {
      name = "requestid"
      type = "string" 
    }
    columns {
      name = "eventid"
      type = "string" 
    }
    columns {
      name = "readonly"
      type = "string" 
    }
    columns {
      name = "resources"
      type = "array<struct<arn:string,accountid:string,type:string>>" 
    }
    columns {
      name = "eventtype"
      type = "string" 
    }
    columns {
      name = "apiversion"
      type = "string" 
    }
    columns {
      name = "recipientaccountid"
      type = "string" 
    }
    columns {
      name = "serviceeventdetails"
      type = "string" 
    }
    columns {
      name = "sharedeventid"
      type = "string" 
    }
    columns {
      name = "vpcendpointid"
      type = "string" 
    }
    columns {
      name = vpcendpointaccountid
      type = "string"
    }
    columns {
      name = eventcategory
      type = "string"
    }
    columns {
      name = addendum
      type = "struct<reason:string,updatedfields:string,originalrequestid:string,originaleventid:string>"
    }
    columns {
      name = sessioncredentialfromconsole
      type = "string"
    }
    columns {
      name = edgedevicedetails
      type = "string"
    }
    columns {
      name = tlsdetails
      type = "struct<tlsversion:string,ciphersuite:string,clientprovidedhostheader:string>"
    }
  }
}