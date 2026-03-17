##############################################
### IAM Identity Center for WorkSpaces
###
### ⚠️ MANUAL SETUP REQUIRED
###
### WorkSpaces directory with IAM Identity Center must be created
### via AWS Console, then imported into Terraform.
###
### Steps:
### 1. Go to WorkSpaces Console → Get Started
### 2. Launch WorkSpaces → Select "Quick Setup"
### 3. Choose "IAM Identity Center" as identity source
### 4. Configure VPC/subnets (use the ones created by this Terraform)
### 5. Complete setup to get directory_id (format: d-xxxxxxxxxx)
### 6. Add directory_id to application_variables.json
### 7. Import: terraform import aws_workspaces_directory.workspaces[0] d-xxxxxxxxxx
### 8. Run: terraform apply
###
### IAM Identity Center Instance:
### arn:aws:sso:::instance/ssoins-7535d9af4f41fb26
##############################################

# No directory service resources - IAM Identity Center directory
# is created manually via console and imported
