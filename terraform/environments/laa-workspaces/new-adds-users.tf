##############################################
### User Management with IAM Identity Center
###
### Users are managed entirely in IAM Identity Center.
### No directory service user creation needed.
###
### Setup Process:
### 1. Add users to IAM Identity Center
### 2. If using Office 365, configure federation (Azure AD → IAM Identity Center)
### 3. Assign users to WorkSpaces application in IAM Identity Center
### 4. Create WorkSpaces for users (via Terraform or Console)
###
### Authentication Flow:
### - User opens WorkSpaces → Redirects to IAM Identity Center
### - IAM Identity Center authenticates (Office 365 if federated)
### - User accesses their WorkSpace
###
### No separate directory passwords or user accounts needed.
##############################################

# All user management happens in IAM Identity Center
