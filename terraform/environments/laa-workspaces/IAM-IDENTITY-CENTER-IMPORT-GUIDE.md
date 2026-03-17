# WorkSpaces with IAM Identity Center - Manual Creation & Import Guide

## Overview

This guide walks through creating a WorkSpaces directory with IAM Identity Center via AWS Console, then importing it into Terraform for ongoing management.

## Architecture

```
Office 365 ←(Federation)→ IAM Identity Center ←(Native)→ WorkSpaces
```

- **No Directory Service** needed (no monthly AD costs)
- **Pure IAM Identity Center** integration
- **Office 365 SSO** via IAM Identity Center federation
- **Users managed** entirely in IAM Identity Center

## Prerequisites

✅ IAM Identity Center instance configured: `arn:aws:sso:::instance/ssoins-7535d9af4f41fb26`
✅ Office 365 federated with IAM Identity Center (or users added directly)
✅ VPC and subnets deployed via Terraform

## Step 1: Deploy Network Infrastructure

First, deploy the VPC and subnets that WorkSpaces will use:

```bash
cd terraform/environments/laa-workspaces

# Deploy VPC, subnets, security groups, IAM roles
terraform apply -target=aws_vpc.workspaces \
                -target=aws_subnet.private_a \
                -target=aws_subnet.private_b \
                -target=aws_iam_role.workspaces_default

# Verify VPC created
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=laa-workspaces-development-vpc" --region eu-west-2
```

Note the subnet IDs — you'll need them for the console setup.

## Step 2: Create WorkSpaces Directory via Console

⚠️ **This step CANNOT be automated via Terraform for IAM Identity Center directories**

### 2.1 Navigate to WorkSpaces Console

1. Go to: https://eu-west-2.console.aws.amazon.com/workspaces/v2/home?region=eu-west-2
2. Click **"Get Started"** or **"Launch WorkSpaces"**

### 2.2 Select Identity Source

1. Choose **"Quick Setup"** or **"Advanced Setup"**
2. For identity source, select: **"IAM Identity Center"**
3. Select your IAM Identity Center instance: `ssoins-7535d9af4f41fb26`

### 2.3 Configure Network

1. **VPC**: Select `laa-workspaces-development-vpc` (created by Terraform)
2. **Subnets**: Select both private subnets:
   - `laa-workspaces-development-private-a` (10.200.1.0/24)
   - `laa-workspaces-development-private-b` (10.200.2.0/24)

### 2.4 Complete Setup

1. Configure any additional settings (IP access control, self-service permissions)
2. Click **"Create Directory"** or **"Complete Setup"**
3. Wait 5-10 minutes for directory creation

### 2.5 Get Directory ID

Once created, note the **Directory ID** (format: `d-xxxxxxxxxx`):

```bash
# List WorkSpaces directories
aws workspaces describe-workspace-directories --region eu-west-2

# Get just the directory ID
aws workspaces describe-workspace-directories \
  --region eu-west-2 \
  --query 'Directories[?State==`REGISTERED`].DirectoryId' \
  --output text
```

Example output: `d-90671bb8e2`

## Step 3: Update Terraform Configuration

Add the directory ID to your configuration:

**Edit `application_variables.json`:**

```json
{
  "accounts": {
    "development": {
      "workspace_bundle_id": "wsb-0q8gwp742",
      "region": "eu-west-2",
      "vpc_cidr": "10.200.0.0/16",
      "private_subnet_a_cidr": "10.200.1.0/24",
      "private_subnet_b_cidr": "10.200.2.0/24",
      "identity_center_instance_arn": "arn:aws:sso:::instance/ssoins-7535d9af4f41fb26",
      "workspaces_directory_id": "d-90671bb8e2"  ← ADD THIS
    },
    ...
  }
}
```

## Step 4: Import Directory into Terraform

```bash
# Import the directory resource
terraform import 'aws_workspaces_directory.workspaces[0]' d-90671bb8e2

# Verify import successful
terraform state show 'aws_workspaces_directory.workspaces[0]'
```

Expected output should show the directory configuration.

## Step 5: Reconcile Configuration

Run `terraform plan` to see if any configuration drift exists:

```bash
terraform plan
```

If Terraform wants to change settings (e.g., IP groups, self-service permissions), you can:
- **Option A**: Update Terraform to match console settings
- **Option B**: Apply changes to align console with Terraform

```bash
# Apply Terraform configuration to the imported directory
terraform apply
```

## Step 6: Verify Setup

### Check Directory Status

```bash
aws workspaces describe-workspace-directories \
  --region eu-west-2 \
  --query 'Directories[0].[DirectoryId,Alias,State,RegistrationCode]' \
  --output table
```

### Get Registration Code

Users will need this to register their WorkSpaces client:

```bash
aws workspaces describe-workspace-directories \
  --region eu-west-2 \
  --query 'Directories[0].RegistrationCode' \
  --output text
```

## Step 7: Configure Office 365 Federation

If not already done, federate Office 365 with IAM Identity Center:

### 7.1 In IAM Identity Center

1. Go to: https://console.aws.amazon.com/singlesignon
2. Settings → Identity source → **Change**
3. Select **"External identity provider"**
4. Download IAM Identity Center SAML metadata

### 7.2 In Azure AD (Office 365)

1. Go to Azure Portal → Azure Active Directory
2. Enterprise applications → **New application**
3. Search for "AWS IAM Identity Center" (formerly AWS SSO)
4. Configure:
   - Upload IAM Identity Center SAML metadata
   - Configure attribute mapping:
     ```
     user.mail → http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress
     user.userprincipalname → http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name
     ```
   - Assign users/groups

### 7.3 Complete Federation

1. Download Azure AD SAML metadata
2. Upload to IAM Identity Center
3. Test federation by logging into IAM Identity Center with Office 365 credentials

## Step 8: Add Users to WorkSpaces

Users must exist in IAM Identity Center to get WorkSpaces.

### Option A: Via Console

1. IAM Identity Center → Users → **Add user**
2. Or assign from Office 365 (if federated automatically)

### Option B: Via Terraform

Add users to `new-workspace-users.tf` or create workspace instances directly:

```hcl
locals {
  workspace_users = {
    "john.doe" = {
      email         = "john.doe@example.com"
      instance_type = "standard"
    }
  }
}
```

Uncomment the `aws_workspaces_workspace` resource in `new-workspaces.tf` and apply.

## Step 9: Create WorkSpaces

### Via Terraform (Recommended)

1. Uncomment workspace resources in `new-workspaces.tf`
2. Define users in locals
3. Apply:

```bash
terraform apply
```

### Via Console

1. WorkSpaces → **Launch WorkSpaces**
2. Select directory
3. Select user from IAM Identity Center
4. Choose bundle and settings
5. Launch

## Step 10: User Login Flow

### First-Time Setup

1. User receives registration email or admin provides registration code
2. User downloads WorkSpaces client: https://clients.amazonworkspaces.com/
3. Enter registration code
4. Redirected to IAM Identity Center login
5. Authenticates with Office 365 credentials
6. WorkSpaces launches

### Subsequent Logins

1. Open WorkSpaces client
2. Automatically redirects to IAM Identity Center
3. SSO via Office 365 (if session active)
4. WorkSpace launches

## Ongoing Management

### Update Directory Configuration

After import, manage settings via Terraform:

```bash
# Modify new-workspaces.tf settings
# Then apply
terraform apply
```

### Add/Remove Users

- **Add**: Create user in IAM Identity Center → Create WorkSpace
- **Remove**: Delete WorkSpace → Optionally remove from IAM Identity Center

### Monitor Costs

```bash
# List all WorkSpaces
aws workspaces describe-workspaces --region eu-west-2

# Check running mode (AutoStop = cost-effective)
aws workspaces describe-workspaces \
  --region eu-west-2 \
  --query 'Workspaces[*].[UserName,State,WorkspaceProperties.RunningMode]' \
  --output table
```

## Troubleshooting

### Import Fails

**Error**: `Resource not found`

**Solution**: Verify directory ID is correct:
```bash
aws workspaces describe-workspace-directories --region eu-west-2
```

### Terraform Wants to Replace Directory

**Error**: `aws_workspaces_directory.workspaces[0] must be replaced`

**Solution**: The `lifecycle { ignore_changes = [directory_id] }` block prevents this. If it still happens:
```bash
terraform state rm 'aws_workspaces_directory.workspaces[0]'
terraform import 'aws_workspaces_directory.workspaces[0]' d-xxxxxxxxxx
```

### User Cannot Log In

**Check 1**: User exists in IAM Identity Center
```bash
aws identitystore list-users \
  --identity-store-id d-9067e452c1 \
  --region eu-west-2
```

**Check 2**: User has a WorkSpace
```bash
aws workspaces describe-workspaces \
  --region eu-west-2 \
  --query 'Workspaces[?UserName==`john.doe`]'
```

**Check 3**: Office 365 federation is working
- Test by logging into IAM Identity Center directly with Office 365 credentials

### Directory Creation Takes Too Long

This is normal — WorkSpaces directories can take 10-15 minutes to provision.

## Cost Analysis

| Component | Monthly Cost |
|-----------|--------------|
| WorkSpaces Directory (IAM Identity Center) | **$0** |
| WorkSpace instance (Standard, AutoStop) | ~$25 per user |
| WorkSpace instance (Standard, Always-On) | ~$35 per user |
| Data transfer | Variable |

**Total for 10 users (AutoStop mode)**: ~$250/month

Compare to Simple AD approach: ~$290/month (adds $40 for directory)

## Security Best Practices

✅ **MFA**: Enforce via IAM Identity Center or Office 365
✅ **IP Restrictions**: Configure IP groups in WorkSpaces
✅ **Encryption**: Enable for root and user volumes
✅ **Auto-Stop**: Use AutoStop mode to reduce costs when not in use
✅ **Monitoring**: Enable CloudWatch logging for WorkSpaces events

## Summary Checklist

- [ ] Deploy VPC/subnets via Terraform
- [ ] Create WorkSpaces directory via Console with IAM Identity Center
- [ ] Note directory ID
- [ ] Add directory ID to `application_variables.json`
- [ ] Import directory: `terraform import`
- [ ] Verify: `terraform plan`
- [ ] Apply: `terraform apply`
- [ ] Configure Office 365 federation (if needed)
- [ ] Add users to IAM Identity Center
- [ ] Create WorkSpaces for users
- [ ] Test user login flow

## Next Steps

Once setup is complete:
1. Document organization-specific login instructions for users
2. Set up monitoring/alerting for WorkSpaces health
3. Configure backup policies if needed
4. Plan regular user access reviews

## Additional Resources

- [AWS WorkSpaces Documentation](https://docs.aws.amazon.com/workspaces/)
- [IAM Identity Center with WorkSpaces](https://docs.aws.amazon.com/singlesignon/latest/userguide/awsapps.html)
- [Office 365 Federation Guide](https://docs.aws.amazon.com/singlesignon/latest/userguide/azure-ad-idp.html)
- [Terraform aws_workspaces_directory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/workspaces_directory)
