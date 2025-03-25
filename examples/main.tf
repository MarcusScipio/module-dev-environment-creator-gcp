/*
Example usage of the GCP Environment Bootstrap Module
*/

module "dev_environment" {
  source = "./gcp-environment-bootstrap"

  # GCP Authentication
  gcp_credentials = file("./service-account-key.json")
  
  # Project Configuration - Create a new project
  create_project  = true
  project_prefix  = "my-dev-project"
  environment_suffix = "dev"
  billing_account = "ABCDEF-123456-GHIJKL"
  region          = "us-central1"
  
  # APIs to enable
  apis_to_enable = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "redis.googleapis.com", 
    "secretmanager.googleapis.com",
    "iam.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com"
  ]
  disable_dependent_services = true
  disable_services_on_destroy = false
  
  # Component Enablement
  enable_components = {
    gke       = true
    databases = true
    redis     = true
    kafka     = false
  }
  
  # Network Configuration
  create_network = true
  network_name   = "dev-vpc"
  subnets = {
    "subnet-gke" = {
      ip_cidr_range = "10.0.0.0/20"
      region        = "us-central1"
      secondary_ip_ranges = {
        "pods"     = "10.16.0.0/14"
        "services" = "10.20.0.0/20"
      }
    }
    "subnet-db" = {
      ip_cidr_range = "10.1.0.0/20"
      region        = "us-central1"
    }
  }
  
  # GKE Configuration
  gke_config = {
    cluster_name      = "dev-cluster"
    node_pool_name    = "main-pool"
    subnet_name       = "subnet-gke"
    machine_type      = "e2-standard-2"
    node_count        = 1
    disk_size_gb      = 100
    disk_type         = "pd-standard"
    preemptible       = true
    service_account   = ""  # Will use the default compute service account
    private_cluster   = true
    private_endpoint  = false
    master_ipv4_cidr_block = "172.16.0.0/28"
    pods_ipv4_cidr_block = "10.16.0.0/14"
    services_ipv4_cidr_block = "10.20.0.0/20"
    http_load_balancing = true
    horizontal_pod_autoscaling = true
    release_channel   = "REGULAR"
  }
  
  # Database Configuration
  database_instances = {
    "primary-db" = {
      database_version  = "MYSQL_8_0"
      region            = "us-central1"
      tier              = "db-custom-2-7680"
      disk_size         = 100
      availability_type = "ZONAL" # Use REGIONAL for production
      enable_backup     = true
      enable_binary_log = true
    }
    "reporting-db" = {
      database_version  = "MYSQL_8_0"
      region            = "us-central1"
      tier              = "db-custom-4-15360"
      disk_size         = 100
      availability_type = "ZONAL"
      enable_backup     = true
      enable_binary_log = true
    }
  }
  
  # Redis Configuration
  redis_config = {
    name           = "dev-redis"
    tier           = "BASIC"
    memory_size_gb = 1
    redis_version  = "REDIS_6_X"
    display_name   = "Development Redis"
    connect_mode   = "DIRECT_PEERING"
    replica_count  = 0
  }
}

# Outputs
output "project_id" {
  value = module.dev_environment.project_id
}

output "gke_cluster_endpoint" {
  value     = module.dev_environment.gke_cluster_endpoint
  sensitive = true
}

output "database_instances" {
  value = module.dev_environment.database_instances
}

output "redis_instance" {
  value = module.dev_environment.redis_instance
}