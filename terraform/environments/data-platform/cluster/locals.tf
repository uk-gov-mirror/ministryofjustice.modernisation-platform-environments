locals {
  environment_configuration = local.environment_configurations[local.environment]
  cluster_configuration     = yamldecode(file("${path.module}/configuration/cluster.yml"))["environment"][local.environment]

  eks_cluster_name                    = "${local.application_name}-${local.environment}"
  eks_cluster_logs_log_group_name     = "/aws/eks/${local.eks_cluster_name}/cluster"
  eks_application_logs_log_group_name = "/aws/eks/${local.eks_cluster_name}/application"

  aps_log_group_name = "/aws/aps/${local.eks_cluster_name}"

  container_insights_log_group_name = "/aws/containerinsights/${local.eks_cluster_name}/performance"

  ##
  ## Kyverno privileged securityContext exception policies.
  ##
  ## Each entry produces one ClusterPolicy that allows pods matching the given
  ## namespace(s) and label selector to run with privileged: true.
  ##
  ## Fields
  ## ──────
  ##   name                 – unique slug; becomes part of the ClusterPolicy name
  ##   description          – human-readable reason stored as a policy annotation
  ##   namespaces           – list of namespaces the rule applies to
  ##   pod_selector_labels  – map of label key→value used to narrow the match to
  ##                          specific pods (use {} to match all pods in the namespace)
  ##
  kyverno_privileged_policies = [
    {
      name        = "cloudwatch-agent"
      description = "The CloudWatch agent DaemonSet requires privileged mode to collect host-level metrics and kernel performance data."
      namespaces  = [module.aws_cloudwatch_observability_namespace.name]
      pod_selector_labels = {
        "app.kubernetes.io/name" = "cloudwatch-agent"
      }
    },
    # ── Template: add further services below ──────────────────────────────────
    # {
    #   name        = "my-service"
    #   description = "Short justification for why privileged mode is needed."
    #   namespaces  = ["my-namespace"]
    #   pod_selector_labels = {
    #     "app.kubernetes.io/name" = "my-service"
    #   }
    # },
    # ─────────────────────────────────────────────────────────────────────────
  ]
}
