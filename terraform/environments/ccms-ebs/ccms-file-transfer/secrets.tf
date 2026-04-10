#### This file can be used to store secrets specific to the sftp client account ####

# PUI Application Secrets
resource "aws_secretsmanager_secret" "sftp_barclaycard_secrets" {
  name        = "${local.application_name}-sftp-barclaycard-secrets"
  description = "PUI Application Secrets"
}

resource "aws_secretsmanager_secret_version" "sftp_barclaycard_secrets" {
  secret_id = aws_secretsmanager_secret.sftp_barclaycard_secrets.id
  secret_string = jsonencode({
    ebs_db_username       = "",
    ebs_db_password       = "",
    ebs_db_endpoint       = "",
    file_transfer_slack_webhook  = ""
  })

#   lifecycle {
#     ignore_changes = [
#       secret_string
#     ]
#   }
}

data "aws_secretsmanager_secret_version" "sftp_barclaycard_secrets" {
  secret_id = aws_secretsmanager_secret.sftp_barclaycard_secrets.id
}
