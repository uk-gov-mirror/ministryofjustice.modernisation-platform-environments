#!/usr/bin/env bash

# This scripts exists because the Terraform Kubernetes provider does not pass assumed credentials from the default AWS provider

AWS_ACCOUNT_ID=${1}
EKS_CLUSTER_NAME=${2}
AWS_ROLE=${3:-MemberInfrastructureAccess}


aws eks get-token --cluster-name "${EKS_CLUSTER_NAME}"
