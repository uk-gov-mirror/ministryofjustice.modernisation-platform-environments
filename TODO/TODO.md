# Cluster Builout

---

## TODO

- [ ] Review chart values
- [ ] Look at AWS Backup for EKS https://docs.aws.amazon.com/aws-backup/latest/devguide/eks-backups.html

---

```
aws-sso exec --profile data-platform-${STAGE:-"development"}:platform-engineer-admin
aws-sso exec --profile data-platform-${STAGE:-"test"}:platform-engineer-admin
aws-sso exec --profile data-platform-${STAGE:-"preproduction"}:platform-engineer-admin
aws-sso exec --profile data-platform-${STAGE:-"production"}:platform-engineer-admin

aws eks update-kubeconfig --name ${AWS_SSO_PROFILE%%:*}

terraform init && terraform workspace select ${AWS_SSO_PROFILE%%:*} && terraform apply
```