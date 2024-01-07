locals {
  base_name = "${var.stack_name}-${var.env_name}"
  base_tag  = "${local.base_name}-all"

  bastion_openvpn_name = "${local.base_name}-openvpn"
  bastion_openvpn_tag  = "${local.base_name}-openvpn"

  aaa_gke_cluster            = "${local.base_name}-aaa"
  aaa_gke_cluster_pods_range = "10.96.0.0/20"
  aaa_gke_cluster_svc_range  = "10.100.16.0/24"
  aaa_gke_cluster_tag        = local.aaa_gke_cluster
  aaa_gke_pool_aaa           = "pool-aaa"
  aaa_gke_pool_aaa_tag       = local.aaa_gke_pool_aaa
}
