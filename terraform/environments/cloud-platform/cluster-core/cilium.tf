module "cilium" {
  count  = contains(["development_cluster"], local.cluster_environment) ? 1 : 0
  source = "github.com/ministryofjustice/container-platform-terraform-cilium?ref=1.1.1" # use the latest release
}
