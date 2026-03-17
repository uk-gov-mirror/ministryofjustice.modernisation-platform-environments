##############################################
### User Management with IAM Identity Center
###
### ⚠️ Users are managed in IAM Identity Center
### 
### With IAM Identity Center, users are NOT created in AWS Directory Service.
### Instead, they are managed in IAM Identity Center which can be:
### - Federated with Office 365 (Azure AD)
### - Federated with Okta, Google Workspace, etc.
### - Managed directly in IAM Identity Center
###
### To provision WorkSpaces for a user:
### 1. Ensure user exists in IAM Identity Center
### 2. Configure IAM Identity Center federation (if using external IdP)
### 3. Add user to appropriate IAM Identity Center groups
### 4. Create WorkSpace using their IAM Identity Center username
###
### User authentication happens via IAM Identity Center SSO.
##############################################

# No user creation needed - users are managed in IAM Identity Center

# Users authenticate with IAM Identity Center credentials:
# - If federated with Office 365: Office 365 email/password
# - If federated with Okta: Okta credentials
# If IAM Identity Center native: IAM Identity Center username/password
