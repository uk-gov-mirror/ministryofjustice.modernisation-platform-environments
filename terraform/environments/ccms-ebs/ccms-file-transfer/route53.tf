# DNS Configuration

# Creates Route53 DNS records for the SFTP Barclaycard LB in Non-Prod
resource "aws_route53_record" "route53_record_sftp_barclaycard_nonprod" {
  count    = local.is-production ? 0 : 1
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = local.application_data.accounts[local.environment].app_name
  type     = "A"

  alias {
    name                   = aws_lb.sftp_barclaycard_load_balancer.dns_name
    zone_id                = aws_lb.sftp_barclaycard_load_balancer.zone_id
    evaluate_target_health = false
  }
}


# Creates Route53 DNS records for the SFTP Barclaycard LB in PROD
resource "aws_route53_record" "route53_record_sftp_barclaycard_prod" {
  count    = local.is-production ? 1 : 0
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.laa.zone_id
  name     = local.application_data.accounts[local.environment].app_name
  type     = "A"
  alias {
    name                   = aws_lb.sftp_barclaycard_load_balancer.dns_name
    zone_id                = aws_lb.sftp_barclaycard_load_balancer.zone_id
    evaluate_target_health = false
  }
}