module "network" {
  source  = "terraform-google-modules/network/google"
  version = "~> 8.1"

  project_id   = var.project_id
  network_name = local.base_name
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name   = "bastion"
      subnet_ip     = "10.255.255.0/29"
      subnet_region = var.region
    },
    {
      subnet_name   = "gke-cluster"
      subnet_ip     = "10.100.255.0/24"
      subnet_region = var.region
    }
  ]

  secondary_ranges = {
    gke-cluster = [
      {
        range_name    = "gke-cluster-pods"
        ip_cidr_range = "10.96.0.0/20"
      },
      {
        range_name    = "gke-cluster-services"
        ip_cidr_range = "10.100.16.0/24"
      }
    ]
  }

  ingress_rules = [
    {
      name          = "${local.base_name}-internet-to-bastion-via-ssh"
      source_ranges = ["0.0.0.0/0"]
      target_tags   = [local.bastion_tag]
      allow         = [
        {
          protocol = "TCP"
          port     = ["22"]
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

#module "bastion_ip" {
#  source  = "terraform-google-modules/address/google"
#  version = "~> 3.2"
#
#  names      = [local.bastion_name]
#  project_id = var.project_id
#  region     = var.region
#
#  global       = false
#  address_type = "EXTERNAL"
#}
#
#module "bastion_sa" {
#  source  = "terraform-google-modules/service-accounts/google"
#  version = "~> 4.2.2"
#
#  names      = [local.bastion_name]
#  project_id = var.project_id
#}
#
#module "bastion_instance_template" {
#  source  = "terraform-google-modules/vm/google//modules/instance_template"
#  version = "~> 10.1.1"
#
#  name_prefix = local.bastion_name
#  project_id  = var.project_id
#  region      = var.region
#
#  machine_type         = "e2-standard-2"
#  disk_size_gb         = "32"
#  disk_type            = "pd-ssd"
#  source_image_project = "ubuntu-os-cloud"
#  source_image         = "ubuntu-2204-lts"
#  subnetwork           = module.network.subnets["${var.region}/bastion"].self_link
#  tags                 = [local.bastion_tag, local.tag_all]
#  metadata             = {
#    ssh-keys = var.terraform_user_ssh_pub_key
#  }
#  service_account = {
#    email  = module.bastion_sa.email
#    scopes = [
#      "https://www.googleapis.com/auth/compute"
#    ]
#  }
#}
#
#module "bastion_compute_instance" {
#  source  = "terraform-google-modules/vm/google//modules/compute_instance"
#  version = "~> 10.1.1"
#
#  hostname = local.bastion_name
#  region   = var.region
#  zone     = "${var.region}-a"
#
#  instance_template   = module.bastion_instance_template.self_link
#  subnetwork          = module.network.subnets["${var.region}/bastion"].self_link
#  num_instances       = 1
#  deletion_protection = false
#
#  access_config = [
#    {
#      nat_ip       = module.bastion_ip.addresses[0]
#      network_tier = "PREMIUM"
#    },
#  ]
#}

module "gke_cluster_sa" {
  source  = "terraform-google-modules/service-accounts/google"
  version = "~> 4.2.2"

  names      = [local.gke_cluster_name]
  project_id = var.project_id
}

module "gke_cluster" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version = "29.0.0"

  project_id = var.project_id
  name       = local.base_name
  region     = var.region

  zones      = ["${var.region}-a", "${var.region}-b", "${var.region}-c"]
  network    = module.network.network_name
  subnetwork = module.network.subnets["${var.region}/gke-cluster"].name

  ip_range_pods     = "gke-cluster-pods"
  ip_range_services = "gke-cluster-services"

  deletion_protection        = false
  remove_default_node_pool   = true
  http_load_balancing        = false
  network_policy             = false
  horizontal_pod_autoscaling = false
  filestore_csi_driver       = false
  enable_private_endpoint    = false
  enable_private_nodes       = true
  master_ipv4_cidr_block     = "10.100.101.240/28"

  master_authorized_networks = [
    {
      cidr_block   = var.remote_access_cidr
      display_name = "ActiveAddress"
    },
    #    {
    #      cidr_block   = "${module.bastion_ip.addresses[0]}/32"
    #      display_name = "BastionExternal"
    #    },
    {
      cidr_block   = module.network.subnets["${var.region}/gke-cluster"].ip_cidr_range
      display_name = "BastionInternal"
    }
  ]

  logging_enabled_components           = []
  monitoring_enabled_components        = []
  monitoring_service                   = null
  monitoring_enable_managed_prometheus = false

  node_pools = [
    #    {
    #      name               = "generic"
    #      machine_type       = "e2-highcpu-2"
    #      node_locations     = "${var.region}-a"
    #      initial_node_count = 0
    #      min_count          = 0
    #      max_count          = 0
    #      local_ssd_count    = 0
    #      spot               = false
    #      preemptible        = false
    #      disk_type          = "pd-ssd"
    #      disk_size_gb       = 32
    #      image_type         = "COS_CONTAINERD"
    #      enable_gcfs        = false
    #      enable_gvnic       = false
    #      logging_variant    = "DEFAULT"
    #      auto_repair        = true
    #      auto_upgrade       = true
    #      service_account    = module.gke_cluster_sa.email
    #    },
    {
      name               = "spot"
      machine_type       = "n2d-highcpu-2"
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
      service_account    = module.gke_cluster_sa.email
    }
  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  node_pools_labels = {
    all     = {}
    generic = {}
    spot    = {}
  }

  node_pools_resource_labels = {
    all     = {}
    generic = {}
    spot    = {}
  }

  node_pools_metadata = {
    all     = {}
    generic = {}
    spot    = {}
  }

  node_pools_taints = {
    all     = []
    generic = []
    spot    = []
  }

  node_pools_tags = {
    all     = []
    generic = [
      local.tag_all,
      local.gke_pool_generic_tag
    ]
    spot = [
      local.tag_all,
      local.gke_pool_spot_tag
    ]
  }
}