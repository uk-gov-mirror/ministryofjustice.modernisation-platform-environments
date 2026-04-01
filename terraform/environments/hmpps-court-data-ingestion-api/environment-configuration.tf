locals {
  environment_configuration = {
    development = {
      cloud_platform_sqs_queue_name = "calculate-release-dates-team-dev-hmpps_court_data_ingestion_queue"
      secret_ingestion_api_auth_token_secret_arn = module.secret_ingestion_api_auth_token_dev.secret_arn
    }
    preproduction = {
      cloud_platform_sqs_queue_name = "calculate-release-dates-team-preprod-hmpps_court_data_ingestion_queue"
      secret_ingestion_api_auth_token_secret_arn = module.secret_ingestion_api_auth_token_preprod.secret_arn
    }
    production = {
      cloud_platform_sqs_queue_name = "calculate-release-dates-team-prod-hmpps_court_data_ingestion_queue"
      secret_ingestion_api_auth_token_secret_arn = module.secret_ingestion_api_auth_token_prod.secret_arn
    }
  }
}
