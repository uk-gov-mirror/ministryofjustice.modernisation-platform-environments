resource "aws_secretsmanager_secret" "ldap_test_users" {
  #checkov:skip=CKV2_AWS_57
  name        = "ldap-test-users"
  description = "A list of LDAP test users for export prior to data refresh"
  kms_key_id  = var.account_config.kms_keys.general_shared
  tags        = var.tags
}
