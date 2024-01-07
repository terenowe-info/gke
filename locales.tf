locals {
  base_name = "${var.stack_name}-${var.env_name}"
  base_tag  = "${local.base_name}-all"

  management_base_name = "${local.base_name}-management"
  management_ip_range  = "10.255.255.0/24"

  vm_openvpn_name      = "openvpn"
  vm_openvpn_base_name = "${local.base_name}-${local.vm_openvpn_name}"
  vm_openvpn_tag       = local.vm_openvpn_base_name
  vm_openvpn_static_ip = "10.255.255.100"

  aaa_gke_cluster_name           = "aaa"
  aaa_gke_cluster_base_name      = "${local.base_name}-${local.aaa_gke_cluster_name}"
  aaa_gke_cluster_spec_name      = "gke-${local.base_name}-${local.aaa_gke_cluster_name}"
  aaa_gke_cluster_tag            = local.aaa_gke_cluster_base_name
  aaa_gke_cluster_nodes_ip_range = "10.100.255.0/24"
  aaa_gke_cluster_pods_ip_range  = "10.96.0.0/20"
  aaa_gke_cluster_svc_ip_range   = "10.100.16.0/24"
  aaa_gke_cluster_pool_aaa       = "pool-aaa"
  aaa_gke_cluster_pool_aaa_tag   = local.aaa_gke_cluster_pool_aaa

  aaa_gke_cluster_lb_base_name = "${local.base_name}-${local.aaa_gke_cluster_name}-lb"
  aaa_gke_cluster_lb_spec_name = "gke-${local.base_name}-${local.aaa_gke_cluster_name}-lb"
  aaa_gke_cluster_lb_ip_range  = "10.150.150.0/24"
}
