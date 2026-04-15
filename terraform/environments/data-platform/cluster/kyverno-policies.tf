resource "kubernetes_manifest" "kyverno_privileged_policy" {
  for_each = { for policy in local.kyverno_privileged_policies : policy.name => policy }

  manifest = {
    apiVersion = "kyverno.io/v1"
    kind       = "ClusterPolicy"

    metadata = {
      name = "enforce-${each.value.name}-privileged"
    }

    spec = {
      rules = [
        {
          name = "set-privileged-true"

          match = {
            resources = {
              kinds      = ["Pod"]
              namespaces = each.value.namespaces
              selector = {
                matchLabels = each.value.pod_selector_labels
              }
            }
          }

          mutate = {
            patchStrategicMerge = {
              spec = {
                containers = [
                  {
                    # (name) is a Kyverno anchor – matches all containers
                    # without filtering by name.
                    "(name)" = "*"
                    securityContext = {
                      privileged = true
                    }
                  }
                ]
                initContainers = [
                  {
                    "(name)" = "*"
                    securityContext = {
                      privileged = true
                    }
                  }
                ]
              }
            }
          }
        }
      ]
    }
  }

  depends_on = [helm_release.kyverno]
}
