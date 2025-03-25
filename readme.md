# Universal GCP Environment Bootstrap Module

This module provides a reusable, configurable foundation for quickly bootstrapping development environments on Google Cloud Platform. It automates the creation of common infrastructure components using Terraform and GitHub Actions.

## Features

- **Project Creation**: Optionally create a new GCP project
- **API Management**: Dynamically enable required Google Cloud APIs
- **Networking**: Set up VPC, subnets, and Cloud NAT
- **Kubernetes Engine**: Create GKE clusters with configurable node pools
- **Databases**: Provision Cloud SQL instances with proper networking
- **Caching**: Set up Redis instances for application caching
- **CI/CD Integration**: GitHub Actions workflow for automated provisioning

## Prerequisites

- Google Cloud Platform account
- Appropriate IAM permissions
- Service account with necessary roles
- GitHub repository for CI/CD automation
- Terraform Cloud or GCS bucket for state management

## Usage

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
  
  # Enable only what you need
  enable_components = {
    gke       = true
    databases = true
    redis     = true
    kafka     = false
  }
  
  # Network Configuration
  create_network = true
  network_name   = "dev-vpc"
  
  # Add your other configurations as needed...
}
```

### Advanced Configuration

For more detailed examples, see the [examples](./examples) directory.

## Module Structure

```
.
├── main.tf             # Main module logic
├── variables.tf        # Variable definitions
├── outputs.tf          # Module outputs
├── examples/           # Usage examples
│   └── basic/          # Basic usage
│   └── multi-env/      # Multi-environment setup
└── modules/            # Sub-modules (if applicable)
```

## GitHub Actions Integration

This module includes a GitHub Actions workflow to automate the provisioning process. To use it:

1. Copy the `.github/workflows/terraform.yml` file to your repository
2. Set up the required GitHub Secrets:
   - `GCP_CREDENTIALS`: Service account JSON key
   - `GCP_BILLING_ACCOUNT`: GCP billing account ID
   - `GCP_FOLDER_ID`: Optional folder ID
   - `PROJECT_PREFIX`: Prefix for project names
   - `TF_STATE_BUCKET`: GCS bucket for Terraform state

The workflow supports:
- Automated validation on pull requests
- Plan output as PR comments
- Manual or automated applies
- Environment-specific deployments
- Destroy functionality for clean-up

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| gcp_credentials | GCP service account credentials JSON | `string` | n/a | yes |
| existing_project_id | Existing GCP project ID | `string` | `""` | no |
| create_project | Whether to create a new GCP project | `bool` | `false` | no |
| project_prefix | Prefix for the project name | `string` | `"dev-env"` | no |
| environment_suffix | Suffix to append to resource names | `string` | `""` | no |
| billing_account | Billing account ID | `string` | `""` | no |
| region | Primary GCP region for resources | `string` | `"us-central1"` | no |
| ... | ... | ... | ... | ... |

## Outputs

| Name | Description |
|------|-------------|
| project_id | The ID of the GCP project |
| network | The VPC network |
| subnets | The created subnets |
| gke_cluster_name | The name of the GKE cluster |
| gke_cluster_endpoint | The endpoint of the GKE cluster |
| database_instances | The created database instances |
| redis_instance | The created Redis instance |

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This module is licensed under the MIT License - see the LICENSE file for details.