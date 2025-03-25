# Universal GCP Environment Bootstrap Module

This module provides a reusable, configurable foundation for quickly bootstrapping development environments on Google Cloud Platform. It automates the creation of common infrastructure components using Terraform and GitHub Actions.

## 🌟 Features

- **Project Creation**: Optionally create a new GCP project with proper billing setup
- **API Management**: Dynamically enable and manage Google Cloud APIs with configurable clean-up behavior
- **Networking**: Set up VPC networks, subnets, and Cloud NAT for outbound connectivity
- **Kubernetes Engine**: Create GKE clusters with configurable node pools, networking, and security settings
- **Databases**: Provision Cloud SQL instances with proper networking, backup configuration, and user management
- **Caching**: Set up Redis instances for application caching with configurable sizing and settings
- **Modular Approach**: Enable only the components you need for your environment
- **Environment Flexibility**: Support for multiple environments (dev, test, staging) through configuration
- **CI/CD Integration**: GitHub Actions workflow for automated provisioning and management

## 📋 Prerequisites

- Google Cloud Platform account
- Service account with necessary permissions:
  - Project Creator (if creating new projects)
  - Project IAM Admin
  - Compute Admin
  - Kubernetes Engine Admin
  - Service Usage Admin
  - Cloud SQL Admin
  - Redis Admin
- GitHub repository for CI/CD automation (if using GitHub Actions)
- GCS bucket for Terraform state management (recommended)

## 🚀 Quick Start

1. Copy this module to your repository or reference it directly
2. Configure the required variables in a `terraform.tfvars` file
3. Initialize and apply the Terraform configuration
4. Optionally, set up the GitHub Actions workflow for ongoing management

## 💻 Usage

### Basic Example

```hcl
module "dev_environment" {
  source = "github.com/your-org/gcp-environment-bootstrap"

  # GCP Authentication
  gcp_credentials = file("./service-account-key.json")
  
  # Project Configuration
  create_project     = true
  project_prefix     = "my-dev-project"
  environment_suffix = "dev"
  billing_account    = "ABCDEF-123456-GHIJKL"
  region             = "us-central1"
  
  # APIs to enable (customize as needed)
  apis_to_enable = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "redis.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com"
  ]
  disable_services_on_destroy = false  # Don't disable APIs on destroy
  
  # Component Configuration
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
    service_account   = ""  # Default compute service account
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
      availability_type = "ZONAL"  # Use REGIONAL for production
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
```

### Full Configuration Reference

For a complete list of configuration options, refer to the [variables.tf](./variables.tf) file or the [Variables](#-variables) section below.

## 📁 Module Structure

```
.
├── main.tf             # Main module configuration
├── variables.tf        # Input variable definitions
├── outputs.tf          # Output definitions
├── examples/           # Example configurations
│   └── basic/          # Basic usage example
│   └── multi-env/      # Multi-environment example
└── .github/workflows/  # GitHub Actions workflow definitions
```

## 🔄 GitHub Actions Integration

The module includes a GitHub Actions workflow that automates the deployment process. To use it:

1. Create the directory `.github/workflows/` in your repository
2. Copy the `gcp-environment.yml` file from this module to that directory
3. Configure the required GitHub repository secrets:

| Secret Name | Description |
|-------------|-------------|
| `GCP_CREDENTIALS` | Service account JSON key with required permissions |
| `GCP_BILLING_ACCOUNT` | GCP billing account ID for project creation |
| `GCP_FOLDER_ID` | Optional folder ID for project organization |
| `TF_STATE_BUCKET` | GCS bucket for Terraform state storage |
| `PROJECT_PREFIX` | Prefix for project names (optional) |

### Workflow Features

- **Automated Validation**: Validates Terraform configurations on pull requests
- **Plan Visibility**: Shows Terraform plans as PR comments for review
- **Environment Selection**: Supports different environments (dev, test, staging)
- **Action Selection**: Supports plan, apply, and destroy operations
- **Security**: Uses Google's recommended authentication practices

### Triggering the Workflow

The workflow can be triggered in several ways:
- Automatically on push to main branch
- Automatically on pull requests that modify Terraform files
- Manually through the GitHub Actions UI with environment and action selection

## 📝 Variables

### Core Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `gcp_credentials` | GCP service account credentials JSON | `string` | n/a | yes |
| `create_project` | Whether to create a new GCP project | `bool` | `false` | no |
| `existing_project_id` | Existing GCP project ID (if not creating a new project) | `string` | `""` | no |
| `project_prefix` | Prefix for the project name | `string` | `"dev-env"` | no |
| `environment_suffix` | Suffix to append to resource names | `string` | `""` | no |
| `billing_account` | Billing account ID | `string` | `""` | no |
| `folder_id` | Folder ID for the GCP project | `string` | `""` | no |
| `region` | Primary GCP region for resources | `string` | `"us-central1"` | no |

### API Management

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `apis_to_enable` | List of GCP APIs to enable in the project | `list(string)` | List of common APIs | no |
| `disable_dependent_services` | Whether to disable dependent services when disabling a service | `bool` | `true` | no |
| `disable_services_on_destroy` | Whether to disable services when the Terraform resource is destroyed | `bool` | `true` | no |

### Component Enablement

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `enable_components` | Enable or disable specific components | `object` | All enabled | no |

### Networking

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `create_network` | Whether to create a new VPC network | `bool` | `true` | no |
| `network_name` | Name of the VPC network to create | `string` | `"dev-network"` | no |
| `existing_network` | Existing network self-link if not creating a new network | `string` | `""` | no |
| `existing_subnetwork` | Existing subnetwork self-link if not creating new subnets | `string` | `""` | no |
| `auto_create_subnetworks` | Whether to create auto-mode subnets | `bool` | `false` | no |
| `create_nat` | Whether to create a Cloud NAT gateway | `bool` | `true` | no |
| `subnets` | Map of subnet configurations to create | `map(object)` | Default subnet | no |

### GKE Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `gke_config` | GKE cluster configuration object | `object` | Default GKE config | no |

### Database Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `database_instances` | Map of database instances to create | `map(object)` | Default DB config | no |
| `database_require_ssl` | Whether to require SSL for database connections | `bool` | `false` | no |

### Redis Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `redis_config` | Redis instance configuration object | `object` | Default Redis config | no |

## 📤 Outputs

| Name | Description |
|------|-------------|
| `project_id` | The ID of the provisioned or specified GCP project |
| `network` | The VPC network self-link |
| `subnets` | Map of created subnet self-links |
| `gke_cluster_name` | The name of the GKE cluster (if created) |
| `gke_cluster_endpoint` | The endpoint of the GKE cluster (if created) |
| `database_instances` | Map of created database instance connection names |
| `redis_instance` | The host address of the Redis instance (if created) |

## 🔄 Upgrade Guide

When upgrading to a new version of this module:

1. Review the CHANGELOG for breaking changes
2. Update any required variables in your configuration
3. Run `terraform plan` to verify changes before applying
4. Consider using a new environment suffix for testing changes

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request with improvements or bug fixes.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📜 License

This module is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgements

- Terraform team for their excellent infrastructure as code tool
- Google Cloud Platform for their comprehensive cloud services
- GitHub team for the excellent Actions workflow automation