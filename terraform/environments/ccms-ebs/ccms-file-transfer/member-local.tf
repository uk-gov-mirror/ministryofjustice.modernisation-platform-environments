locals {
  sftp_client1_folder_name = ["inbound", "archive", "error"]
  sftp_client1_bucket_name = "${local.application_name}-${local.environment}-barclaycard-inbound-mp"
  logging_bucket_name      = "${local.application_name}-${local.environment}-logging"

  lambda_source_hashes_process_file_from_bucket = [
    for f in fileset("./lambda/process_file_from_bucket", "**") :
    sha256(file("${path.module}/lambda/process_file_from_bucket/${f}"))
  ]

}