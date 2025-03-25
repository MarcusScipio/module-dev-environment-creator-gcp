/*
GCP Environment Bootstrap Module

This Terraform module creates a development-ready GCP environment with standardized components.
It includes project setup, networking, GKE clusters, databases, and caching services.
*/

locals {
  environment_suffix = var.environment_suffix != "" ? "-${var.environment_suffix}" : ""
  project_id         = var.create_project ? google_project.project[0].project_id : var.existing_project_id

  enable_gke       = var.enable_components.gke
  enable_databases = var.enable_components.databases
  enable_redis     = var.enable_components.redis
  enable_kafka     = var.enable_components.kafka
}

###-------PROVIDERS-------###
terraform {
  required_version = ">= 0.14"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.42.1"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.1"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.4.3"
    }
  }
}

provider "google" {
  credentials = var.gcp_credentials
  project     = local.project_id
  region      = var.region
}

###-------PROJECT CREATION (OPTIONAL)-------###
resource "google_project" "project" {
  count           = var.create_project ? 1 : 0
  name            = "${var.project_prefix}${local.environment_suffix}"
  project_id      = "${var.project_prefix}${local.environment_suffix}"
  billing_account = var.billing_account
  folder_id       = var.folder_id
}

###-------API ENABLEMENT-------###
resource "google_project_service" "api_services" {
  for_each                   = toset(var.apis_to_enable)
  project                    = local.project_id
  service                    = each.key
  disable_dependent_services = var.disable_dependent_services
  disable_on_destroy         = var.disable_services_on_destroy
}

###-------NETWORKING-------###
resource "google_compute_network" "vpc" {
  count                   = var.create_network ? 1 : 0
  name                    = "${var.network_name}${local.environment_suffix}"
  project                 = local.project_id
  auto_create_subnetworks = var.auto_create_subnetworks
  depends_on              = [google_project_service.api_services]
}

resource "google_compute_subnetwork" "subnets" {
  for_each      = var.create_network ? var.subnets : {}
  name          = "${each.key}${local.environment_suffix}"
  project       = local.project_id
  ip_cidr_range = each.value.ip_cidr_range
  region        = each.value.region
  network       = google_compute_network.vpc[0].self_link
  dynamic "secondary_ip_range" {
    for_each = lookup(each.value, "secondary_ip_ranges", {})
    content {
      range_name    = secondary_ip_range.key
      ip_cidr_range = secondary_ip_range.value
    }
  }
}

resource "google_compute_router" "router" {
  count   = var.create_network && var.create_nat ? 1 : 0
  name    = "router${local.environment_suffix}"
  network = var.create_network ? google_compute_network.vpc[0].self_link : var.existing_network
  region  = var.region
}

resource "google_compute_address" "nat_ip" {
  count        = var.create_network && var.create_nat ? 1 : 0
  name         = "nat-ip${local.environment_suffix}"
  address_type = "EXTERNAL"
  region       = var.region
}

resource "google_compute_router_nat" "nat" {
  count                              = var.create_network && var.create_nat ? 1 : 0
  name                               = "nat${local.environment_suffix}"
  router                             = google_compute_router.router[0].name
  region                             = var.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.nat_ip[0].self_link]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  min_ports_per_vm                   = 64
}

###-------GKE CLUSTER-------###
resource "google_container_cluster" "cluster" {
  count                    = local.enable_gke ? 1 : 0
  name                     = "${var.gke_config.cluster_name}${local.environment_suffix}"
  location                 = var.region
  remove_default_node_pool = true
  initial_node_count       = 1
  
  network    = var.create_network ? google_compute_network.vpc[0].self_link : var.existing_network
  subnetwork = var.create_network ? google_compute_subnetwork.subnets[var.gke_config.subnet_name].self_link : var.existing_subnetwork
  
  private_cluster_config {
    enable_private_nodes    = var.gke_config.private_cluster
    enable_private_endpoint = var.gke_config.private_endpoint
    master_ipv4_cidr_block  = var.gke_config.master_ipv4_cidr_block
  }

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = var.gke_config.pods_ipv4_cidr_block
    services_ipv4_cidr_block = var.gke_config.services_ipv4_cidr_block
  }

  # Basic add-ons
  addons_config {
    http_load_balancing {
      disabled = !var.gke_config.http_load_balancing
    }
    horizontal_pod_autoscaling {
      disabled = !var.gke_config.horizontal_pod_autoscaling
    }
  }

  # Release channel
  release_channel {
    channel = var.gke_config.release_channel
  }

  depends_on = [
    google_project_service.api_services
  ]
}

resource "google_container_node_pool" "primary_nodes" {
  count      = local.enable_gke ? 1 : 0
  name       = "${var.gke_config.node_pool_name}${local.environment_suffix}"
  location   = var.region
  cluster    = google_container_cluster.cluster[0].name
  node_count = var.gke_config.node_count

  node_config {
    preemptible  = var.gke_config.preemptible
    machine_type = var.gke_config.machine_type
    disk_size_gb = var.gke_config.disk_size_gb
    disk_type    = var.gke_config.disk_type

    # Google recommends custom service accounts with minimal permissions
    service_account = var.gke_config.service_account
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  depends_on = [
    google_container_cluster.cluster
  ]
}

###-------DATABASES-------###
resource "google_compute_global_address" "private_ip_range" {
  count         = local.enable_databases ? 1 : 0
  name          = "private-ip-range${local.environment_suffix}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.create_network ? google_compute_network.vpc[0].self_link : var.existing_network
}

resource "google_service_networking_connection" "private_vpc_connection" {
  count                   = local.enable_databases ? 1 : 0
  network                 = var.create_network ? google_compute_network.vpc[0].self_link : var.existing_network
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range[0].name]
}

resource "google_sql_database_instance" "db_instances" {
  for_each          = local.enable_databases ? var.database_instances : {}
  name              = "${each.key}${local.environment_suffix}"
  database_version  = each.value.database_version
  region            = each.value.region
  deletion_protection = false # For easier cleanup in dev environments
  
  settings {
    tier              = each.value.tier
    disk_size         = each.value.disk_size
    availability_type = each.value.availability_type
    disk_autoresize   = true
    
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.create_network ? google_compute_network.vpc[0].id : var.existing_network
      require_ssl     = var.database_require_ssl
    }
    
    backup_configuration {
      enabled            = each.value.enable_backup
      binary_log_enabled = each.value.enable_binary_log
      start_time         = "23:00"
    }
  }
  
  depends_on = [
    google_service_networking_connection.private_vpc_connection
  ]
}

###-------REDIS CACHE-------###
resource "google_redis_instance" "cache" {
  count               = local.enable_redis ? 1 : 0
  name                = "${var.redis_config.name}${local.environment_suffix}"
  tier                = var.redis_config.tier
  memory_size_gb      = var.redis_config.memory_size_gb
  region              = var.region
  authorized_network  = var.create_network ? google_compute_network.vpc[0].id : var.existing_network
  redis_version       = var.redis_config.redis_version
  display_name        = "${var.redis_config.display_name}${local.environment_suffix}"
  connect_mode        = var.redis_config.connect_mode
  replica_count       = var.redis_config.replica_count
  
  depends_on = [
    google_project_service.api_services
  ]
}

###-------OUTPUTS-------###
output "project_id" {
  description = "The ID of the GCP project"
  value       = local.project_id
}

output "network" {
  description = "The VPC network"
  value       = var.create_network ? google_compute_network.vpc[0].self_link : var.existing_network
}

output "subnets" {
  description = "The created subnets"
  value       = var.create_network ? { for k, v in google_compute_subnetwork.subnets : k => v.self_link } : {}
}

output "gke_cluster_name" {
  description = "The name of the GKE cluster"
  value       = local.enable_gke ? google_container_cluster.cluster[0].name : null
}

output "gke_cluster_endpoint" {
  description = "The endpoint of the GKE cluster"
  value       = local.enable_gke ? google_container_cluster.cluster[0].endpoint : null
  sensitive   = true
}

output "database_instances" {
  description = "The created database instances"
  value       = local.enable_databases ? { for k, v in google_sql_database_instance.db_instances : k => v.connection_name } : {}
}

output "redis_instance" {
  description = "The created Redis instance"
  value       = local.enable_redis ? google_redis_instance.cache[0].host : null
}