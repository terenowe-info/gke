locals {
  base_name = "${var.stack_name}-${var.env_name}"

  tag_all = "${local.base_name}-all"

  bastion_tag      = "${local.base_name}-bastion"
  bastion_name     = "${local.base_name}-bastion"
  gke_cluster_tag  = "${local.base_name}-gke"
  gke_cluster_name = "${local.base_name}-gke"
}
