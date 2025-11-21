# GCP Network-as-Code with Terraform

A modular Terraform infrastructure-as-code solution for managing Google Cloud Platform (GCP) networking resources. This project enables infrastructure engineers to define and deploy VPC networks, subnets, firewall rules, and custom routes through declarative configuration files.

## Project Purpose

This solution provides:
- **Modular Architecture**: Reusable Terraform modules for VPC, subnets, firewall rules, and routes
- **Multi-Environment Support**: Separate configurations for dev and prod environments with shared module code
- **Infrastructure as Code**: Version-controlled network configurations with reproducible deployments
- **Local Development**: Designed for local Terraform CLI workflows with future CI/CD extensibility

## Folder Structure

```
network-as-code-gcp/
├── modules/                    # Reusable Terraform modules
│   ├── vpc/                   # VPC network creation module
│   │   ├── main.tf           # VPC resource definitions
│   │   ├── variables.tf      # Input variables
│   │   └── outputs.tf        # Output values
│   ├── subnet/               # Subnet management module
│   │   ├── main.tf           # Subnet resource definitions
│   │   ├── variables.tf      # Input variables
│   │   └── outputs.tf        # Output values
│   ├── firewall/             # Firewall rules module
│   │   ├── main.tf           # Firewall resource definitions
│   │   ├── variables.tf      # Input variables
│   │   └── outputs.tf        # Output values
│   └── routes/               # Custom routes module
│       ├── main.tf           # Route resource definitions
│       ├── variables.tf      # Input variables
│       └── outputs.tf        # Output values
├── environments/              # Environment-specific configurations
│   ├── dev/                  # Development environment
│   │   ├── main.tf           # Module invocations
│   │   ├── providers.tf      # Provider configuration
│   │   ├── backend.tf        # State backend configuration
│   │   ├── variables.tf      # Variable declarations
│   │   └── terraform.tfvars  # Variable values
│   └── prod/                 # Production environment
│       ├── main.tf           # Module invocations
│       ├── providers.tf      # Provider configuration
│       ├── backend.tf        # State backend configuration
│       ├── variables.tf      # Variable declarations
│       └── terraform.tfvars  # Variable values
└── README.md                  # This file
```

## Prerequisites

Before using this project, ensure you have the following:

1. **Terraform 1.5+**: Download and install from [terraform.io](https://www.terraform.io/downloads)
   ```bash
   terraform version
   ```

2. **GCP Account**: An active Google Cloud Platform account with a project created

3. **gcloud CLI**: Google Cloud SDK installed and configured
   ```bash
   gcloud version
   ```

4. **Service Account**: A GCP service account with appropriate permissions:
   - `roles/compute.networkAdmin` - For managing VPC, subnets, firewall rules, and routes
   - `roles/iam.serviceAccountUser` - If creating resources that use service accounts

5. **Enabled APIs**: The following GCP APIs must be enabled in your project:
   - Compute Engine API (`compute.googleapis.com`)
   ```bash
   gcloud services enable compute.googleapis.com --project=YOUR_PROJECT_ID
   ```

## Authentication Setup

### Step 1: Create a Service Account

```bash
# Create service account
gcloud iam service-accounts create terraform-network-sa \
  --display-name="Terraform Network Service Account" \
  --project=YOUR_PROJECT_ID

# Grant necessary permissions
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:terraform-network-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/compute.networkAdmin"
```

### Step 2: Create and Download Service Account Key

```bash
gcloud iam service-accounts keys create ~/gcp-terraform-key.json \
  --iam-account=terraform-network-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

### Step 3: Set Environment Variable

```bash
# For macOS/Linux
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/gcp-terraform-key.json"

# Add to your shell profile (~/.bashrc, ~/.zshrc) to persist
echo 'export GOOGLE_APPLICATION_CREDENTIALS="$HOME/gcp-terraform-key.json"' >> ~/.zshrc
```

## Usage Instructions

### Initial Setup

1. **Clone or navigate to the project directory**

2. **Update terraform.tfvars**: Edit the appropriate environment's `terraform.tfvars` file with your project details
   ```bash
   # For dev environment
   cd environments/dev
   # Edit terraform.tfvars with your project_id and desired configuration
   ```

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

### Working with Environments

#### Development Environment

```bash
# Navigate to dev environment
cd environments/dev

# Initialize (first time only)
terraform init

# Preview changes
terraform plan

# Apply changes
terraform apply

# Destroy resources (when done)
terraform destroy
```

#### Production Environment

```bash
# Navigate to prod environment
cd environments/prod

# Initialize (first time only)
terraform init

# Preview changes
terraform plan

# Apply changes
terraform apply

# Destroy resources (when done)
terraform destroy
```

### Using -chdir Flag (Alternative)

You can also run Terraform commands from the project root:

```bash
# Dev environment
terraform -chdir=environments/dev init
terraform -chdir=environments/dev plan
terraform -chdir=environments/dev apply

# Prod environment
terraform -chdir=environments/prod init
terraform -chdir=environments/prod plan
terraform -chdir=environments/prod apply
```

## Remote State Configuration (Optional)

By default, Terraform stores state locally. For team collaboration and state locking, configure remote state using Google Cloud Storage (GCS).

### Step 1: Create GCS Bucket

```bash
# Create bucket for Terraform state
gsutil mb -p YOUR_PROJECT_ID -l US gs://YOUR-TF-STATE-BUCKET

# Enable versioning for state history
gsutil versioning set on gs://YOUR-TF-STATE-BUCKET
```

### Step 2: Configure Backend

1. Edit `backend.tf` in your environment directory (dev or prod)
2. Uncomment the backend configuration block
3. Replace `REPLACE_ME_TF_STATE_BUCKET` with your actual bucket name
4. Save the file

### Step 3: Migrate State

```bash
# Navigate to environment directory
cd environments/dev  # or environments/prod

# Migrate existing state to GCS
terraform init -migrate-state
```

## Module Documentation

### VPC Module (`modules/vpc`)

Creates a custom-mode VPC network in GCP.

**Key Variables:**
- `project_id` (required): GCP project ID
- `network_name` (required): Name for the VPC network
- `routing_mode` (optional, default="GLOBAL"): Routing mode (GLOBAL or REGIONAL)

**Outputs:**
- `network_self_link`: Full self-link URL of the created network
- `network_name`: Name of the created network

### Subnet Module (`modules/subnet`)

Creates multiple subnets across different regions within a VPC.

**Key Variables:**
- `project_id` (required): GCP project ID
- `network_name` (required): Name of the parent VPC network
- `subnets` (required): Map of subnet configurations with region, CIDR range, and settings

**Outputs:**
- `subnet_self_links`: Map of subnet names to their self-link URLs

### Firewall Module (`modules/firewall`)

Creates firewall rules for controlling ingress and egress traffic.

**Key Variables:**
- `project_id` (required): GCP project ID
- `network_name` (required): Name of the VPC network
- `firewall_rules` (required): Map of firewall rule configurations with direction, priority, and allow rules

**Outputs:**
- `firewall_rule_self_links`: Map of rule names to their self-link URLs

### Routes Module (`modules/routes`)

Creates custom routes for directing traffic within or outside the VPC.

**Key Variables:**
- `project_id` (required): GCP project ID
- `network_name` (required): Name of the VPC network
- `routes` (required): Map of route configurations with destination range, priority, and next hop

**Outputs:**
- `route_self_links`: Map of route names to their self-link URLs

## Important Notes

- **Project IDs**: Always replace placeholder project IDs in `terraform.tfvars` with your actual GCP project ID
- **CIDR Ranges**: Ensure dev and prod environments use non-overlapping IP address spaces
- **State Management**: Each environment maintains its own Terraform state file
- **Module Changes**: Changes to modules affect all environments that use them
- **Testing**: Always test changes in dev environment before applying to prod
- **Cleanup**: Use `terraform destroy` to remove all resources when no longer needed

## Troubleshooting

### Authentication Issues
- Verify `GOOGLE_APPLICATION_CREDENTIALS` is set correctly
- Ensure service account key file exists and is valid
- Check service account has necessary IAM permissions

### API Not Enabled
```bash
gcloud services enable compute.googleapis.com --project=YOUR_PROJECT_ID
```

### Quota Exceeded
- Check GCP quotas in Console under IAM & Admin > Quotas
- Request quota increases if needed

### State Lock Errors
- Ensure only one Terraform process runs per environment at a time
- If using GCS backend, check for stale locks in the bucket

## Next Steps

1. Review and customize `terraform.tfvars` in both dev and prod environments
2. Run `terraform plan` to preview infrastructure changes
3. Apply configurations starting with dev environment
4. Verify resources in GCP Console
5. Configure remote state backend for team collaboration
6. Consider setting up CI/CD pipelines for automated deployments

## Support

For issues or questions:
- Review Terraform documentation: https://www.terraform.io/docs
- Review GCP documentation: https://cloud.google.com/docs
- Check module-specific README files (if available)
