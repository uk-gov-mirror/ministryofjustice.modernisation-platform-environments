resource "aws_athena_workgroup" "default" {
  name        = format("%s-default", local.env_account_id)
  description = "A default Athena workgroup to set query limits and link to the default query location bucket: ${module.s3-athena-bucket.bucket.id}"
  state       = "ENABLED"

  configuration {
    bytes_scanned_cutoff_per_query     = 1073741824000 # 1 TB
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${module.s3-athena-bucket.bucket.id}/output/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
      acl_configuration {
        s3_acl_option = "BUCKET_OWNER_FULL_CONTROL"
      }
    }
  }
}


resource "aws_athena_workgroup" "ears_sars" {
  name        = format("%s-ears-sars", local.env_account_id)
  description = "An Athena workgroup for EAR/SARs, dumps to: ${module.s3-athena-bucket.bucket.id}"
  state       = "ENABLED"

  configuration {
    bytes_scanned_cutoff_per_query     = 1073741824000 # 1 TB
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${module.s3-athena-bucket.bucket.id}/output/ears_sars/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
      acl_configuration {
        s3_acl_option = "BUCKET_OWNER_FULL_CONTROL"
      }
    }
  }
}

resource "aws_athena_workgroup" "cadt" {
  name        = "create-a-derived-table"
  description = "An Athena workgroup for cadt, dumps to: ${module.s3-athena-bucket.bucket.id}"
  state       = "ENABLED"

  configuration {
    bytes_scanned_cutoff_per_query     = 1073741824000 # 1 TB
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${module.s3-athena-bucket.bucket.id}/output/cadt/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
      acl_configuration {
        s3_acl_option = "BUCKET_OWNER_FULL_CONTROL"
      }
    }
  }
}

resource "aws_athena_workgroup" "cadt-historic-dev" {
  count       = local.is-production ? 1 : 0
  name        = "create-a-derived-table-historic-dev"
  description = "An Athena workgroup for cadt historic dev, dumps to: ${module.s3-athena-bucket.bucket.id}"
  state       = "ENABLED"

  configuration {
    bytes_scanned_cutoff_per_query     = 1073741824000 # 1 TB
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${module.s3-athena-bucket.bucket.id}/output/cadt/historic_dev/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
      acl_configuration {
        s3_acl_option = "BUCKET_OWNER_FULL_CONTROL"
      }
    }
  }
}


resource "aws_glue_catalog_database" "ears_sars_audit_db" {
  count = local.is-development || local.is-preproduction ? 1 : 0  
  name = "ears_sars_audit"
}
resource "aws_glue_catalog_table" "ears_sars_audit_table" {
  count = local.is-development || local.is-preproduction ? 1 : 0
  name          = "reports_requested"
  database_name = aws_glue_catalog_database.ears_sars_audit_db.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "classification"              = "json"
    "projection.enabled"          = "true"
    "projection.year.type"        = "integer"
    "projection.year.range"       = "2025,2040"
    "projection.month.type"       = "integer"
    "projection.month.range"      = "1,12"
    "projection.day.type"         = "integer"
    "projection.day.range"        = "1,31"
    
    "storage.location.template" = "s3://${module.s3-logging-bucket.bucket.id}/ears_sars/$${year}/$${month}/$${day}/"
  }
  storage_descriptor {
    location      = "s3://${module.s3-logging-bucket.bucket.id}/ears_sars/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }
    columns {
      name = "body"
      type = "string"
    }
  }
  partition_keys {
    name = "year"
    type = "string"
  }
  partition_keys {
    name = "month"
    type = "string"
  }
  partition_keys {
    name = "day"
    type = "string"
  }
}