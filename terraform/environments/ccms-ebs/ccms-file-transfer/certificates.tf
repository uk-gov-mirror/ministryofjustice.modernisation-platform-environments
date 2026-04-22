## Certificates
#   *.laa-development.modernisation-platform.service.justice.gov.uk
#   *.laa-test.modernisation-platform.service.justice.gov.uk
#   *.laa-preproduction.modernisation-platform.service.justice.gov.uk
#   *.laa.service.justice.gov.uk

# Certificate

moved {
  from = aws_acm_certificate.external_sftp_barclaycard
  to   = aws_acm_certificate.external_sftp_bc
}

resource "aws_acm_certificate" "external_sftp_bc" {
  validation_method         = "DNS"
  domain_name               = local.primary_domain
  subject_alternative_names = local.subject_alternative_names

  tags = merge(local.tags,
    { Environment = local.environment }
  )
}

## Validation Records

moved {
  from = aws_route53_record.external_validation_sftp_barclaycard_nonprod
  to   = aws_route53_record.external_validation_sftp_bc_nonprod
}

resource "aws_route53_record" "external_validation_sftp_bc_nonprod" {
  count    = local.is-production ? 0 : length(local.modernisation_platform_validations)
  provider = aws.core-vpc

  allow_overwrite = true
  name            = local.modernisation_platform_validations[count.index].name
  records         = [local.modernisation_platform_validations[count.index].record]
  ttl             = 60
  type            = local.modernisation_platform_validations[count.index].type
  zone_id         = data.aws_route53_zone.external.zone_id
}

moved {
  from = aws_route53_record.external_validation_sftp_barclaycard_prod
  to   = aws_route53_record.external_validation_sftp_bc_prod
}

resource "aws_route53_record" "external_validation_sftp_bc_prod" {
  count    = local.is-production ? length(local.laa_validations) : 0
  provider = aws.core-network-services

  allow_overwrite = true
  name            = local.laa_validations[count.index].name
  records         = [local.laa_validations[count.index].record]
  ttl             = 60
  type            = local.laa_validations[count.index].type
  zone_id         = data.aws_route53_zone.laa.zone_id
}

## Certificate Validation

moved {
  from = aws_acm_certificate_validation.external_sftp_barclaycard_nonprod
  to   = aws_acm_certificate_validation.external_sftp_bc_nonprod
}

resource "aws_acm_certificate_validation" "external_sftp_bc_nonprod" {
  count = local.is-production ? 0 : 1

  depends_on = [
    aws_route53_record.external_validation_sftp_bc_nonprod
  ]

  certificate_arn         = aws_acm_certificate.external_sftp_bc.arn
  validation_record_fqdns = [for record in aws_route53_record.external_validation_sftp_bc_nonprod : record.fqdn]

  timeouts {
    create = "10m"
  }
}

moved {
  from = aws_acm_certificate_validation.external_sftp_barclaycard_prod
  to   = aws_acm_certificate_validation.external_sftp_bc_prod
}

resource "aws_acm_certificate_validation" "external_sftp_bc_prod" {
  count = local.is-production ? 1 : 0

  depends_on = [
    aws_route53_record.external_validation_sftp_bc_prod
  ]

  certificate_arn         = aws_acm_certificate.external_sftp_bc.arn
  validation_record_fqdns = [for record in aws_route53_record.external_validation_sftp_bc_prod : record.fqdn]

  timeouts {
    create = "10m"
  }
}