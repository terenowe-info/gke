locals {
  base_name = "${var.stack_name}-${var.env_name}"

  tag_all = "${local.base_name}-all"

  bastion_name          = "${local.base_name}-bastion"
  bastion_tag           = "${local.base_name}-bastion"
  gke_cluster_name      = "${local.base_name}-gke"
  gke_cluster_tag       = "${local.base_name}-gke"
  gke_pool_generic_name = "${local.base_name}-gke-pool-generic"
  gke_pool_generic_tag  = "${local.base_name}-gke-pool-generic"
  gke_pool_spot_name    = "${local.base_name}-gke-pool-spot"
  gke_pool_spot_tag     = "${local.base_name}-gke-pool-spot"
}
