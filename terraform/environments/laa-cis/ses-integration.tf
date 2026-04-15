#####################################
# SES Route53 Records
#####################################

locals {
  ses_domain_identity = "cis-dev.modernisation-platform.service.justice.gov.uk"

  ses_dkim_records = [
    {
      name  = "cn3hj46ubipkybq7lags7szz2sb6jdk5._domainkey.cis-dev.modernisation-platform.service.justice.gov.uk"
      type  = "CNAME"
      value = "cn3hj46ubipkybq7lags7szz2sb6jdk5.dkim.amazonses.com"
    },
    {
      name  = "m7unpkilg3jsqxhpp5x7hq6qp7rr33pt._domainkey.cis-dev.modernisation-platform.service.justice.gov.uk"
      type  = "CNAME"
      value = "m7unpkilg3jsqxhpp5x7hq6qp7rr33pt.dkim.amazonses.com"
    },
    {
      name  = "cpmyvcm6ap2rzfd7lbzwohmwx2ychtx2._domainkey.cis-dev.modernisation-platform.service.justice.gov.uk"
      type  = "CNAME"
      value = "cpmyvcm6ap2rzfd7lbzwohmwx2ychtx2.dkim.amazonses.com"
    },
  ]

  ses_mail_from_mx_record = {
    name     = "mail.cis-dev.modernisation-platform.service.justice.gov.uk"
    priority = 10
    type     = "MX"
    value    = "feedback-smtp.eu-west-2.amazonses.com"
  }

  ses_mail_from_spf_record = {
    name  = "mail.cis-dev.modernisation-platform.service.justice.gov.uk"
    type  = "TXT"
    value = "v=spf1 include:amazonses.com ~all"
  }
}

resource "aws_route53_record" "ses_dkim" {
  provider = aws.core-network-services
  for_each = { for record in local.ses_dkim_records : record.name => record }

  zone_id = data.aws_route53_zone.network-services.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 600
  records = [each.value.value]
}

resource "aws_route53_record" "ses_mail_from_mx" {
  provider = aws.core-network-services

  zone_id = data.aws_route53_zone.network-services.zone_id
  name    = local.ses_mail_from_mx_record.name
  type    = local.ses_mail_from_mx_record.type
  ttl     = 600
  records = ["${local.ses_mail_from_mx_record.priority} ${local.ses_mail_from_mx_record.value}"]
}

resource "aws_route53_record" "ses_mail_from_spf" {
  provider = aws.core-network-services

  zone_id = data.aws_route53_zone.network-services.zone_id
  name    = local.ses_mail_from_spf_record.name
  type    = local.ses_mail_from_spf_record.type
  ttl     = 600
  records = [local.ses_mail_from_spf_record.value]
}
