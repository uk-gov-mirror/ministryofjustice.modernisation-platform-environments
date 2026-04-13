locals {
  sftp_barclaycard_folder_name = ["inbound", "archive", "error"]
  sftp_barclaycard_bucket_name = "${local.application_name}-${local.environment}-barclaycard-inbound-mp"
  logging_bucket_name          = "${local.application_name}-${local.environment}-logging"

  lambda_source_hashes_process_file_from_bucket = [
    for f in fileset("./lambda/process_file_from_bucket", "**") :
    sha256(file("${path.module}/lambda/process_file_from_bucket/${f}"))
  ]

  # Certificate configuration based on environment
  nonprod_domain = format("%s-%s.modernisation-platform.service.justice.gov.uk", var.networking[0].business-unit, local.environment)
  prod_domain    = "laa.service.justice.gov.uk"

  # Primary domain name based on environment
  primary_domain = local.is-production ? local.prod_domain : local.nonprod_domain

  # Subject Alternative Names based on environment
  nonprod_sans = [
    format("%s-sftp-barclaycard.%s-%s.modernisation-platform.service.justice.gov.uk", local.application_name, var.networking[0].business-unit, local.environment)
  ]

  prod_sans = [
    format("%s-sftp-barclaycard.%s", local.application_name, local.prod_domain)
  ]

  subject_alternative_names = local.is-production ? local.prod_sans : local.nonprod_sans

  # Domain validation options mapping (following the example pattern)
  domain_types = { for dvo in aws_acm_certificate.external_sftp_barclaycard.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
    }
  }

  # Split domain validation by domain type
  modernisation_platform_validations = [for k, v in local.domain_types : v if strcontains(k, "modernisation-platform.service.justice.gov.uk")]
  laa_validations                    = [for k, v in local.domain_types : v if strcontains(k, "laa.service.justice.gov.uk")]

}