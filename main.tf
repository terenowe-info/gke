################################################
#
#   Networking
#
module "network" {
  source  = "terraform-google-modules/network/google"
  version = "~> 8.1"

  project_id   = var.project_id
  network_name = local.base_name
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name   = local.management_base_name
      subnet_ip     = local.management_ip_range
      subnet_region = var.region
    },
    {
      subnet_name   = local.aaa_gke_cluster_spec_name
      subnet_ip     = local.aaa_gke_cluster_nodes_ip_range
      subnet_region = var.region
    },
    {
      subnet_name   = local.aaa_gke_cluster_lb_spec_name
      subnet_ip     = local.aaa_gke_cluster_lb_ip_range
      subnet_region = var.region
    }
  ]

  secondary_ranges = {
    "${local.aaa_gke_cluster_spec_name}" = [
      {
        range_name    = "${local.aaa_gke_cluster_spec_name}-pods"
        ip_cidr_range = local.aaa_gke_cluster_pods_ip_range
      },
      {
        range_name    = "${local.aaa_gke_cluster_spec_name}-services"
        ip_cidr_range = local.aaa_gke_cluster_svc_ip_range
      }
    ]
  }

  ingress_rules = [
    {
      name          = "${local.base_name}-internet-to-bastion-via-ssh"
      source_ranges = [var.remote_access_cidr]
      target_tag    = [local.vm_openvpn_tag]
      allow         = [
        {
          protocol = "TCP"
          ports    = ["22"]
        },
        {
          protocol = "TCP"
          ports    = ["443", "943", "1194"]
        },
        {
          protocol = "UDP"
          ports    = ["443", "943", "1194"]
        }
      ]
    }
  ]
}

module "cloud_router" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "~> 6.0"

  name    = local.base_name
  region  = var.region
  project = var.project_id

  network = module.network.network_name
}

module "cloud_nat" {
  source  = "terraform-google-modules/cloud-nat/google"
  version = "~> 5.0"

  name       = local.base_name
  project_id = var.project_id
  region     = var.region

  router = module.cloud_router.router.name
}

################################################
#
#   Instance    -   OpenVPN
#
module "openvpn_sa" {
  source  = "terraform-google-modules/service-accounts/google"
  version = "~> 4.2.2"

  names      = [local.vm_openvpn_base_name]
  project_id = var.project_id
}

module "openvpn_ip" {
  source  = "terraform-google-modules/address/google"
  version = "~> 3.2"

  names      = [local.vm_openvpn_base_name]
  project_id = var.project_id
  region     = var.region

  global       = false
  address_type = "EXTERNAL"
}

module "openvpn_instance_template" {
  source  = "terraform-google-modules/vm/google//modules/instance_template"
  version = "~> 10.1.1"

  name_prefix = local.vm_openvpn_base_name
  project_id  = var.project_id
  region      = var.region

  machine_type         = "e2-highcpu-2"
  disk_size_gb         = "32"
  disk_type            = "pd-ssd"
  source_image_project = "ubuntu-os-cloud"
  source_image         = "ubuntu-2204-lts"
  subnetwork           = module.network.subnets["${var.region}/${local.management_base_name}"].self_link
  tags                 = [local.vm_openvpn_tag, local.base_tag]
  metadata             = {
    ssh-keys = var.terraform_user_ssh_pub_key
  }
  service_account = {
    email  = module.openvpn_sa.email
    scopes = [
      "https://www.googleapis.com/auth/compute"
    ]
  }
}

module "openvpn_compute_instance" {
  source  = "terraform-google-modules/vm/google//modules/compute_instance"
  version = "~> 10.1.1"

  hostname            = local.vm_openvpn_base_name
  region              = var.region
  zone                = "${var.region}-a"
  instance_template   = module.openvpn_instance_template.self_link
  subnetwork          = module.network.subnets["${var.region}/${local.management_base_name}"].self_link
  static_ips          = [local.vm_openvpn_static_ip]
  num_instances       = 1
  deletion_protection = false

  access_config = [
    {
      nat_ip       = module.openvpn_ip.addresses[0]
      network_tier = "PREMIUM"
    },
  ]
}

################################################
#
#   GKE Cluster
#
module "aaa_gke_cluster_sa" {
  source  = "terraform-google-modules/service-accounts/google"
  version = "~> 4.2.2"

  names      = [local.aaa_gke_cluster_spec_name]
  project_id = var.project_id
}

module "aaa_gke_cluster" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version = "29.0.0"

  project_id = var.project_id
  name       = local.aaa_gke_cluster_base_name
  region     = var.region

  zones      = ["${var.region}-a"]
  network    = module.network.network_name
  subnetwork = module.network.subnets["${var.region}/${local.aaa_gke_cluster_spec_name}"].name

  ip_range_pods     = "${local.aaa_gke_cluster_spec_name}-pods"
  ip_range_services = "${local.aaa_gke_cluster_spec_name}-services"

  deletion_protection        = false
  http_load_balancing        = false
  network_policy             = false
  horizontal_pod_autoscaling = false
  filestore_csi_driver       = false
  enable_private_endpoint    = false
  remove_default_node_pool   = true
  enable_private_nodes       = true
  master_ipv4_cidr_block     = "10.100.101.240/28"

  master_authorized_networks = [
    {
      cidr_block   = var.remote_access_cidr
      display_name = "ActiveAddress"
    },
    {
      cidr_block   = module.network.subnets["${var.region}/${local.aaa_gke_cluster_spec_name}"].ip_cidr_range
      display_name = "BastionInternal"
    },
    {
      cidr_block   = "${module.openvpn_ip.addresses[0]}/32"
      display_name = "OpenVPNExternalAddress"
    },
  ]

  #monitoring_service = "none"
  monitoring_enable_managed_prometheus = true
  monitoring_enabled_components        = [
    "SYSTEM_COMPONENTS", "APISERVER", "SCHEDULER", "CONTROLLER_MANAGER",
    "STORAGE", "HPA", "POD", "DAEMONSET", "DEPLOYMENT", "STATEFULSET"
  ]

  #logging_service    = "none"
  logging_enabled_components = [
    "SYSTEM_COMPONENTS", "APISERVER", "CONTROLLER_MANAGER", "SCHEDULER", "WORKLOADS"
  ]

  node_pools = [
    {
      name               = local.aaa_gke_cluster_pool_aaa
      machine_type       = "e2-standard-4"
      node_locations     = "${var.region}-a"
      initial_node_count = 1
      min_count          = 1
      max_count          = 1
      local_ssd_count    = 0
      spot               = false
      preemptible        = true
      disk_type          = "pd-ssd"
      disk_size_gb       = 32
      image_type         = "COS_CONTAINERD"
      enable_gcfs        = false
      enable_gvnic       = false
      logging_variant    = "DEFAULT"
      auto_repair        = true
      auto_upgrade       = true
      service_account    = module.aaa_gke_cluster_sa.email
    }
  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  node_pools_labels = {
    all  = {}
    spot = {}
  }

  node_pools_resource_labels = {
    all  = {}
    spot = {}
  }

  node_pools_metadata = {
    all  = {}
    spot = {}
  }

  node_pools_taints = {
    all  = []
    spot = []
  }

  node_pools_tags = {
    all  = []
    spot = [
      local.base_tag,
      local.aaa_gke_cluster_tag,
      local.aaa_gke_cluster_pool_aaa_tag
    ]
  }
}

module "sigma_prod_terenowe_dns_zone" {
  source  = "terraform-google-modules/cloud-dns/google"
  version = "~> 5.0"

  project_id                         = var.project_id
  type                               = "public"
  name                               = "sigma-prod-terenowe-seems-cloud"
  domain                             = "sigma.prod.terenowe.seems.cloud."
  private_visibility_config_networks = [
    module.network.network_self_link
  ]

  enable_logging = false

  recordsets = [
    {
      name    = ""
      type    = "NS"
      ttl     = 60
      records = [
        "ns-cloud-a1.googledomains.com.",
        "ns-cloud-a2.googledomains.com.",
        "ns-cloud-a3.googledomains.com.",
        "ns-cloud-a4.googledomains.com.",
      ]
    },
    {
      name    = "vpn.local"
      type    = "A"
      ttl     = 60
      records = [local.vm_openvpn_static_ip]
    },
    {
      name    = "vpn"
      type    = "A"
      ttl     = 60
      records = [module.openvpn_ip.addresses[0]]
    },
    {
      name    = "headers"
      type    = "A"
      ttl     = 60
      records = ["34.118.4.44"]
    },
    {
      name    = "argocd.local"
      type    = "A"
      ttl     = 60
      records = ["10.150.150.150"]
    },
  ]
}

module "bajojajo_com" {
  source  = "terraform-google-modules/cloud-dns/google"
  version = "~> 5.0"

  project_id                         = var.project_id
  type                               = "public"
  name                               = "sigma-bajojajo-com"
  domain                             = "sigma.bajojajo.com."
  private_visibility_config_networks = [
    module.network.network_self_link
  ]

  enable_logging = false

  recordsets = [
    {
      name    = ""
      type    = "NS"
      ttl     = 60
      records = [
        "ns-cloud-c1.googledomains.com.",
        "ns-cloud-c2.googledomains.com.",
        "ns-cloud-c3.googledomains.com.",
        "ns-cloud-c4.googledomains.com.",
      ]
    },
    {
      name    = "headers"
      type    = "A"
      ttl     = 60
      records = ["34.118.4.44"]
    },
  ]
}
