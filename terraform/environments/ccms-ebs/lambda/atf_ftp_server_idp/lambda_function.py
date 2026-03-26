"""
AWS Lambda function to authenticate client
"""
import json
import os
import logging
import io
import tracemalloc
from dataclasses import dataclass
from typing import Any, Dict, Optional, Union, cast
from datetime import datetime
import boto3
import pycurl
from botocore.exceptions import ClientError
from mypy_boto3_secretsmanager import SecretsManagerClient

logger = logging.getLogger()
logger.setLevel(logging.INFO)

@dataclass
class Config:
    """Configuration settings for the Lambda function."""

    @classmethod
    def from_env(cls) -> "Config":
        """Create configuration from environment variables."""
        return cls()

class ConfigValidator:
    """Validator class for configuration validation."""

    @staticmethod
    def validate_mandatory_fields(config_dict: Dict[str, Any], field_name: str) -> None:
        """Validate that all mandatory fields are present and non-empty."""
        mandatory_fields = {
            "atf_user1_username": config_dict.get("atf_user1_username"),
            "atf_user1_password": config_dict.get("atf_user1_password"),
            "atf_user1_home_directory": config_dict.get("atf_user1_home_directory"),
            "atf_user1_public_key": config_dict.get("atf_user1_public_key"),
            "atf_user1_role": config_dict.get("atf_user1_role"),
            "servername": config_dict.get("servername"),
        }
        missing_fields = [name for name, value in mandatory_fields.items() if not value]
        if missing_fields:
            raise ValueError(
                f"Missing required {field_name} fields: {', '.join(missing_fields)}"
            )

    @staticmethod
    def get_mandatory_secret(secrets_data: Dict, key: str) -> str:
        """Extract and validate a mandatory field from secrets."""
        value = secrets_data.get(key)
        if not value or not isinstance(value, str):
            raise ValueError(
                f"{key} must be a non-empty string in secrets, got: {value}"
            )
        return value

    @staticmethod
    def get_optional_secret(secrets_data: Dict, key: str) -> Optional[str]:
        """Extract and validate an optional field from secrets."""
        value = secrets_data.get(key)
        if value is not None and not isinstance(value, str):
            raise ValueError(
                f"{key} must be a string in secrets, got: {type(value).__name__}"
            )
        return value if value else None

    @staticmethod
    def get_mandatory_env(env_data: Dict, key: str) -> str:
        """Extract and validate a mandatory field from environment."""
        value = env_data.get(key)
        if not value:
            raise ValueError(f"{key} environment variable is required")
        return value


@dataclass
class ValidateConfig:
    """Configuration with validation."""

    atf_user1_username: str
    atf_user1_password: str
    atf_user1_home_directory: str
    atf_user1_role: str
    atf_user1_public_key: str
    servername: str

    def __post_init__(self):
        """Validate configuration after initialization."""
        config_dict = {
            "atf_user1_username": self.atf_user1_username,
            "atf_user1_password": self.atf_user1_password,
            "atf_user1_home_directory": self.atf_user1_home_directory,
            "atf_user1_role": self.atf_user1_role,
            "atf_user1_public_key": self.atf_user1_public_key,
            "servername": self.servername
        }

        ConfigValidator.validate_mandatory_fields(config_dict, "configuration")
        logger.info("Configuration validated")


class SecretsManager:
    """Manager for retrieving configuration from AWS Secrets Manager."""

    def __init__(self):
        self.client = cast(SecretsManagerClient, boto3.client("secretsmanager"))
        logger.info("Initialized Secrets Manager client")

    def get_credentials(self, secret_name: str) -> Dict[str, Union[str, int, bool]]:
        """Retrieve and parse credentials from Secrets Manager."""
        try:
            logger.info(f"Retrieving secret: {secret_name}")
            response = self.client.get_secret_value(SecretId=secret_name)

            # Parse the secret string
            secret_data = json.loads(response["SecretString"])
            logger.info(
                f"Successfully retrieved credentials with {len(secret_data)} keys"
            )

            return secret_data

        except ClientError as e:
            error_code = e.response["Error"]["Code"]
            error_msg = f"Failed to retrieve secret {secret_name}: {error_code}"
            logger.error(error_msg)
            raise Exception(error_msg)
        except json.JSONDecodeError as e:
            error_msg = f"Failed to parse secret JSON: {e}"
            logger.error(error_msg)
            raise Exception(error_msg)


def parse_config_from_env_and_secrets(
    env_data: Dict[str, Optional[str]], secrets_data: Dict[str, Union[str, int, bool]]
) -> ValidateConfig:
    """
    Parse configuration from both environment variables and secrets data.

    This function combines non-sensitive configuration from environment variables
    with sensitive credentials from AWS Secrets Manager.
    """
    
    config = ValidateConfig(
        atf_user1_username=ConfigValidator.get_mandatory_secret(
            secrets_data, "atf_user1_username"
        ),
        atf_user1_password=ConfigValidator.get_mandatory_secret(
            secrets_data, "atf_user1_password"
        ),
        atf_user1_home_directory=ConfigValidator.get_mandatory_secret(
            secrets_data, "atf_user1_home_directory"
        ),
        atf_user1_public_key=ConfigValidator.get_mandatory_secret(
            secrets_data, "atf_user1_public_key"
        ),
        atf_user1_role=ConfigValidator.get_mandatory_secret(
            secrets_data, "atf_user1_role"
        ),
        servername=ConfigValidator.get_mandatory_secret(
            secrets_data, "servername"
        ),
    )

    return config


sm = boto3.client("secretsmanager")

def lambda_handler(event, context):
    """
    Main Lambda handler function. 
    
    This function gets triggered by sftp login.
    """
    # logger.info(event)
    # logger.info(context)
    tracemalloc.start()
    response = {}
    env_config = {
        # Mandatory environment variables (currently none)
    }

    # Get secret name from environment or event
    secret_name = os.environ.get("SECRET_NAME", event.get("secret_name"))
    if not secret_name:
        raise ValueError("SECRET_NAME not found in environment or event")
    if not isinstance(secret_name, str):
        raise ValueError(
            f"SECRET_NAME must be a string, got: {type(secret_name).__name__}"
        )
    logger.info("Retrieving credentials from AWS Secrets Manager")
    server_id = event["serverId"]
    username = event["username"]
    secrets_manager = SecretsManager()
    full_secret_name = f"aws/transfer/{server_id}/{username}"

    secrets_data = secrets_manager.get_credentials(full_secret_name)

    required_secrets = [
        "atf_user1_username",
        "atf_user1_password",
        "atf_user1_home_directory",
        "atf_user1_public_key",
        "atf_user1_role",
        "servername" 
    ]
    missing_secrets = [key for key in required_secrets if key not in secrets_data]
    if missing_secrets:
        raise ValueError(f"Missing required secrets: {', '.join(missing_secrets)}")

    # Parse combined configuration
    logger.info("Parsing configuration from environment and secrets")
    # logger.info(secrets_data)

    config = parse_config_from_env_and_secrets(env_config, secrets_data)

    username = config.atf_user1_username
    password = config.atf_user1_password
    # server_id = event["serverId"]
    # secret = sm.get_secret_value(
    #     SecretId=f"aws/transfer/{server_id}/{username}"
    # )
    # data = json.loads(secret["SecretString"])
    
    # Validate password and Validate SSH public key
    # logger.info(event)
    # public_key = event.get("publicKey")
    # logger.info(f"Public key received: {public_key}")
    response = {
      'Role': config.atf_user1_role,
      'HomeDirectory': config.atf_user1_home_directory
    };
    if event.get('password', '') == '':
        # If no password provided, return the user's SSH public key
        response['PublicKeys'] = [config.atf_user1_public_key]
        logger.info(response)
        return response
    if "password" in event and event["password"] == password:
        return response
    # return response
    # if "password" in event and event["password"] == password and "publicKey" in event and event["publicKey"] == config.atf_user1_public_key:
    #     logger.info("private key is validated")
    #     return {
    #         "Role": config.atf_user1_role,
    #         "HomeDirectory": config.atf_user1_home_directory,
    #     }
    # if "password" in event and event["password"] == password:
    #     return {
    #         "Role": config.atf_user1_role,
    #         "HomeDirectory": config.atf_user1_home_directory,
    #     }

    # if "publicKey" in event and event["publicKey"] == config.atf_user1_public_key:
    #     return {
    #         "Role": data["Role"],
    #         "HomeDirectory": data["HomeDirectory"],
    #     }
    # logger.info("private key is invalid")
    logger.info("errorMessage: Authentication failed")
    return {"errorMessage": "Authentication failed"}