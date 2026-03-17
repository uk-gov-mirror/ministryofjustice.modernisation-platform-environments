##############################################
### IAM Identity Center for WorkSpaces
### 
### WorkSpaces will use IAM Identity Center
### (AWS SSO) as the identity source.
### 
### No Directory Service needed!
### Users authenticate with IAM Identity Center
##############################################

# Note: IAM Identity Center integration for WorkSpaces
# is configured through the WorkSpaces directory resource
# or may require initial setup via AWS Console/CLI
#
# IAM Identity Center Instance:
# arn:aws:sso:::instance/ssoins-7535d9af4f41fb26
#
# Users will authenticate with IAM Identity Center credentials
# which can be federated with Office 365, Okta, or other IdPs

# No Directory Service resources needed with IAM Identity Center
