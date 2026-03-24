import json, boto3

sm = boto3.client("secretsmanager")

def lambda_handler(event, context):
    username = event["username"]
    server_id = event["serverId"]
    secret = sm.get_secret_value(
        SecretId=f"aws/transfer/{server_id}/{username}"
    )
    data = json.loads(secret["SecretString"])

    # Validate password
    if "password" in event and event["password"] == data["Password"]:
        return {
            "Role": data["Role"],
            "HomeDirectory": data["HomeDirectory"],
        }

    # Validate SSH public key
    if "publicKey" in event and event["publicKey"] == data["PublicKey"]:
        return {
            "Role": data["Role"],
            "HomeDirectory": data["HomeDirectory"],
        }

    return {"errorMessage": "Authentication failed"}