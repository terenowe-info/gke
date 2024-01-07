locals {
  base_name = "${var.stack_name}-${var.env_name}"
  base_tag = "${local.base_name}-all"

  bastion_openvpn_name = "${local.base_name}-openvpn"
  bastion_openvpn_tag  = "${local.base_name}-openvpn"

  gke_cluster       = local.base_name
  gke_cluster_tag  = "${local.base_name}-gke"
  gke_pool_aaa      = "${local.base_name}-gke-pool-aaa"
  gke_pool_aaa_tag = "${local.base_name}-gke-pool-aaa"
}
