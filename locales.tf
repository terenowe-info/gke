locals {
  base_name = "${var.stack_name}-${var.env_name}"
  base_tag  = "${local.base_name}-all"

  bastion_openvpn_name = "${local.base_name}-openvpn"
  bastion_openvpn_tag  = "${local.base_name}-openvpn"

  aaa_gke_cluster      = "${local.base_name}-gke-aaa"
  aaa_gke_cluster_tag  = "${local.base_name}-gke-aaa"
  aaa_gke_pool_aaa     = "${local.aaa_gke_cluster}-pool-aaa"
  aaa_gke_pool_aaa_tag = "${local.aaa_gke_cluster_tag}-pool-aaa"

  bbb_gke_cluster      = "${local.base_name}-gke-bbb"
  bbb_gke_cluster_tag  = "${local.base_name}-gke-bbb"
  bbb_gke_pool_aaa     = "${local.bbb_gke_cluster}-pool-aaa"
  bbb_gke_pool_aaa_tag = "${local.bbb_gke_cluster_tag}-pool-aaa"
}
