locals {
    sftp_client1_folder_name = ["inbound", "archive", "error"]
    logging_bucket_name            = "${local.application_name}-${local.environment}-logging"
}