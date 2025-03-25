variable "gcp_credentials" {
  description = "GCP service account credentials JSON"
  type        = string
  sensitive   = true
}

variable "create_nat" {
  description = "Whether to create a Cloud NAT gateway"
  type        = bool
  default     = true
}

# GKE variables
variable "gke_config" {
  description = "GKE cluster configuration"
  type = object({
    cluster_name          = string
    node_pool_name        = string
    subnet_name           = string
    machine_type          = string
    node_count            = number
    disk_size_gb          = number
    disk_type             = string
    preemptible           = bool
    service_account       = string
    private_cluster       = bool
    private_endpoint      = bool
    master_ipv4_cidr_block = string
    pods_ipv4_cidr_block   = string
    services_ipv4_cidr_block = string
    http_load_balancing   = bool
    horizontal_pod_autoscaling = bool
    release_channel       = string
  })
  default = {
    cluster_name          = "dev-cluster"
    node_pool_name        = "primary-pool"
    subnet_name           = "subnet-01"
    machine_type          = "e2-standard-2"
    node_count            = 1
    disk_size_gb          = 100
    disk_type             = "pd-standard"
    preemptible           = true
    service_account       = ""
    private_cluster       = true
    private_endpoint      = false
    master_ipv4_cidr_block = "172.16.0.0/28"
    pods_ipv4_cidr_block   = "10.16.0.0/14"
    services_ipv4_cidr_block = "10.20.0.0/20"
    http_load_balancing   = true
    horizontal_pod_autoscaling = true
    release_channel       = "REGULAR"
  }
}

# Database variables
variable "database_instances" {
  description = "Map of database instances to create"
  type = map(object({
    database_version  = string
    region            = string
    tier              = string
    disk_size         = number
    availability_type = string
    enable_backup     = bool
    enable_binary_log = bool
  }))
  default = {
    "primary-db" = {
      database_version  = "MYSQL_8_0"
      region            = "us-central1"
      tier              = "db-n1-standard-1"
      disk_size         = 10
      availability_type = "ZONAL"
      enable_backup     = true
      enable_binary_log = true
    }
  }
}

variable "database_require_ssl" {
  description = "Whether to require SSL for database connections"
  type        = bool
  default     = false
}

# Redis variables
variable "redis_config" {
  description = "Redis instance configuration"
  type = object({
    name              = string
    tier              = string
    memory_size_gb    = number
    redis_version     = string
    display_name      = string
    connect_mode      = string
    replica_count     = number
  })
  default = {
    name              = "dev-redis"
    tier              = "BASIC"
    memory_size_gb    = 1
    redis_version     = "REDIS_6_X"
    display_name      = "Development Redis"
    connect_mode      = "DIRECT_PEERING"
    replica_count     = 0
  }
}

variable "existing_project_id" {
  description = "Existing GCP project ID (if not creating a new project)"
  type        = string
  default     = ""
}

variable "create_project" {
  description = "Whether to create a new GCP project"
  type        = bool
  default     = false
}

variable "project_prefix" {
  description = "Prefix for the project name if creating a new project"
  type        = string
  default     = "dev-env"
}

variable "environment_suffix" {
  description = "Suffix to append to resource names (e.g. 'dev', 'staging')"
  type        = string
  default     = ""
}

variable "billing_account" {
  description = "Billing account ID for the GCP project (required if creating a project)"
  type        = string
  default     = ""
}

variable "folder_id" {
  description = "Folder ID for the GCP project (optional)"
  type        = string
  default     = ""
}

variable "region" {
  description = "Primary GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "apis_to_enable" {
  description = "List of GCP APIs to enable in the project"
  type        = list(string)
  default = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "redis.googleapis.com",
    "secretmanager.googleapis.com",
    "iam.googleapis.com"
  ]
}

variable "disable_dependent_services" {
  description = "Whether to disable dependent services when disabling a service"
  type        = bool
  default     = true
}

variable "disable_services_on_destroy" {
  description = "Whether to disable services when the Terraform resource is destroyed"
  type        = bool
  default     = true
}

variable "enable_components" {
  description = "Enable or disable specific components"
  type = object({
    gke       = bool
    databases = bool
    redis     = bool
    kafka     = bool
  })
  default = {
    gke       = true
    databases = true
    redis     = true
    kafka     = false
  }
}

# Networking variables
variable "create_network" {
  description = "Whether to create a new VPC network"
  type        = bool
  default     = true
}

variable "network_name" {
  description = "Name of the VPC network to create"
  type        = string
  default     = "dev-network"
}

variable "existing_network" {
  description = "Existing network self-link if not creating a new network"
  type        = string
  default     = ""
}

variable "existing_subnetwork" {
  description = "Existing subnetwork self-link if not creating new subnets"
  type        = string
  default     = ""
}

variable "auto_create_subnetworks" {
  description = "Whether to create auto-mode subnets"
  type        = bool
  default     = false
}

variable "subnets" {
  description = "Map of subnet configurations to create"
  type = map(object({
    ip_cidr_range      = string
    region             = string
    secondary_ip_ranges = optional(map(string))
  }))
  default = {
    "subnet-01" = {
      ip_cidr_range = "10.0.0.0/20"
      region        = "us-central1"
      secondary_ip_ranges = {
        "pods"     = "10.16.0.0/14"
        "services" = "10.20.0.0/20"
      }
    }
  }
}