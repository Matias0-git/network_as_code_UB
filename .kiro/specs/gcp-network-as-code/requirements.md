# Requirements Document

## Introduction

This document specifies the requirements for a Terraform-based Network-as-Code solution for Google Cloud Platform (GCP). The system will enable infrastructure engineers to manage VPC networking resources (networks, subnets, firewall rules, and routes) through declarative configuration files using a modular, multi-environment approach. The solution will support local development and testing with Terraform CLI, with future extensibility for CI/CD integration via GitHub Actions.

## Glossary

- **Terraform**: An infrastructure-as-code tool that allows users to define and provision cloud infrastructure using declarative configuration files
- **VPC (Virtual Private Cloud)**: An isolated network environment within GCP that provides networking functionality for cloud resources
- **Subnet**: A segmented piece of a VPC network with a specific IP address range, associated with a particular region
- **Firewall Rule**: A network security rule that controls ingress (incoming) or egress (outgoing) traffic to/from GCP resources
- **Route**: A network routing rule that directs traffic from one destination to another within or outside the VPC
- **Module**: A reusable, self-contained collection of Terraform configuration files that encapsulates specific infrastructure components
- **Environment**: A distinct deployment context (e.g., dev, prod) with its own configuration and state
- **GCS (Google Cloud Storage)**: Google's object storage service, used for storing Terraform state files
- **CIDR Range**: Classless Inter-Domain Routing notation for specifying IP address ranges (e.g., 10.0.0.0/24)
- **Terraform State**: A file that tracks the current state of managed infrastructure resources
- **tfvars File**: A Terraform variables file containing environment-specific configuration values

## Requirements

### Requirement 1

**User Story:** As a DevOps engineer, I want to define VPC networks using Terraform modules, so that I can create isolated network environments with consistent configuration across multiple environments.

#### Acceptance Criteria

1. WHEN the VPC module is invoked with a network name and project ID, THEN the system SHALL create a google_compute_network resource in custom mode with auto_create_subnetworks set to false
2. WHEN the VPC module is configured with a routing mode parameter, THEN the system SHALL apply the specified routing mode (REGIONAL or GLOBAL) to the VPC network
3. WHEN the VPC module completes resource creation, THEN the system SHALL output the network self-link and network name for use by dependent modules
4. WHEN the VPC module variables are validated, THEN the system SHALL require project_id and network_name as mandatory string inputs
5. WHERE the routing_mode variable is not provided, THEN the system SHALL default to GLOBAL routing mode

### Requirement 2

**User Story:** As a network administrator, I want to define multiple subnets within a VPC using a single configuration map, so that I can manage regional network segments efficiently without duplicating module code.

#### Acceptance Criteria

1. WHEN the subnet module receives a map of subnet configurations, THEN the system SHALL create a google_compute_subnetwork resource for each entry using for_each iteration
2. WHEN each subnet configuration specifies a region and CIDR range, THEN the system SHALL create the subnet in the specified region with the exact IP CIDR range provided
3. WHEN a subnet configuration includes private_ip_google_access setting, THEN the system SHALL enable or disable private Google access accordingly
4. WHERE private_ip_google_access is not specified in a subnet configuration, THEN the system SHALL default to true
5. WHEN the subnet module completes execution, THEN the system SHALL output a map of subnet self-links keyed by subnet name
6. WHEN the subnet module attaches subnets to a VPC, THEN the system SHALL reference the network using the format "projects/${project_id}/global/networks/${network_name}"

### Requirement 3

**User Story:** As a security engineer, I want to define firewall rules through a parameterized module, so that I can control network traffic with ingress and egress rules that are version-controlled and reproducible.

#### Acceptance Criteria

1. WHEN the firewall module receives a map of firewall rule configurations, THEN the system SHALL create a google_compute_firewall resource for each rule using for_each iteration
2. WHEN a firewall rule specifies direction as INGRESS, THEN the system SHALL configure the rule with source_ranges from the ranges variable
3. WHEN a firewall rule specifies direction as EGRESS, THEN the system SHALL configure the rule with destination_ranges from the ranges variable
4. WHEN a firewall rule includes allow blocks with protocol and ports, THEN the system SHALL create corresponding allow rules in the google_compute_firewall resource
5. WHEN a firewall rule specifies target_tags, source_tags, or destination_tags, THEN the system SHALL apply these tags to the firewall rule configuration
6. WHEN the firewall module completes execution, THEN the system SHALL output a map of firewall rule names to self-links

### Requirement 4

**User Story:** As a network engineer, I want to define custom routes through a Terraform module, so that I can control traffic routing within my VPC and to external destinations.

#### Acceptance Criteria

1. WHEN the routes module receives a map of route configurations, THEN the system SHALL create a google_compute_route resource for each route using for_each iteration
2. WHEN a route configuration specifies a destination range and priority, THEN the system SHALL create the route with the exact dest_range and priority values provided
3. WHEN a route configuration includes next_hop_gateway, THEN the system SHALL configure the route to use the specified gateway as the next hop
4. WHEN a route configuration includes next_hop_ip instead of next_hop_gateway, THEN the system SHALL configure the route to use the specified IP address as the next hop
5. WHEN a route configuration includes tags, THEN the system SHALL apply these tags to limit which instances the route applies to
6. WHEN the routes module completes execution, THEN the system SHALL output a map of route names to self-links

### Requirement 5

**User Story:** As a DevOps engineer, I want separate environment configurations for dev and prod, so that I can deploy identical network architectures with different parameters while maintaining isolation between environments.

#### Acceptance Criteria

1. WHEN an environment configuration is initialized, THEN the system SHALL maintain separate terraform.tfvars files for dev and prod environments under environments/dev and environments/prod directories
2. WHEN an environment's main.tf is executed, THEN the system SHALL invoke all four modules (vpc, subnet, firewall, routes) with environment-specific variables
3. WHEN modules are referenced in environment configurations, THEN the system SHALL use relative paths pointing to ../../modules/{module_name}
4. WHEN environment-specific variables are defined, THEN the system SHALL include project_id, network_name, subnets map, firewall_rules map, and routes map
5. WHEN the subnet module is invoked from an environment, THEN the system SHALL pass the VPC network_name output from the vpc module to ensure proper dependency ordering

### Requirement 6

**User Story:** As a cloud architect, I want to configure the Google provider with project, region, and zone parameters, so that Terraform can authenticate and target the correct GCP project and location.

#### Acceptance Criteria

1. WHEN the provider configuration is defined in providers.tf, THEN the system SHALL specify the google provider with source "hashicorp/google" and version constraint "~> 5.0"
2. WHEN the google provider is configured, THEN the system SHALL accept project, region, and zone as variables
3. WHEN Terraform initializes the provider, THEN the system SHALL authenticate using the GOOGLE_APPLICATION_CREDENTIALS environment variable
4. WHEN the required_providers block is defined, THEN the system SHALL specify terraform version requirement of ">= 1.5.0"
5. WHEN each environment has its own providers.tf, THEN the system SHALL allow independent provider configuration for dev and prod environments

### Requirement 7

**User Story:** As a DevOps engineer, I want a GCS backend configuration template with placeholders, so that I can later configure remote state storage without modifying the core Terraform structure.

#### Acceptance Criteria

1. WHEN the backend.tf file is created in each environment directory, THEN the system SHALL include a commented-out terraform backend "gcs" block
2. WHEN the backend configuration template is provided, THEN the system SHALL include placeholder values for bucket (REPLACE_ME_TF_STATE_BUCKET) and prefix (network-as-code/dev or network-as-code/prod)
3. WHEN the backend.tf file is reviewed, THEN the system SHALL include comments instructing users to uncomment and configure the backend after creating a GCS bucket
4. WHEN the backend configuration is commented out, THEN the system SHALL default to local state storage for initial testing

### Requirement 8

**User Story:** As a developer, I want a clear folder structure separating modules from environment configurations, so that I can understand the project organization and locate files quickly.

#### Acceptance Criteria

1. WHEN the project structure is created, THEN the system SHALL organize files into modules/ and environments/ top-level directories
2. WHEN modules are organized, THEN the system SHALL create separate subdirectories for vpc, subnet, firewall, and routes under modules/
3. WHEN each module directory is created, THEN the system SHALL include main.tf, variables.tf, and outputs.tf files
4. WHEN environment directories are created, THEN the system SHALL include dev/ and prod/ subdirectories under environments/
5. WHEN each environment directory is populated, THEN the system SHALL include main.tf, providers.tf, backend.tf, variables.tf, and terraform.tfvars files
6. WHEN the project root is created, THEN the system SHALL include a README.md file documenting the project structure and usage

### Requirement 9

**User Story:** As a new team member, I want comprehensive documentation in the README, so that I can understand the project purpose, structure, and how to execute Terraform commands locally.

#### Acceptance Criteria

1. WHEN the README.md is created, THEN the system SHALL include sections describing project purpose, folder structure, prerequisites, and usage instructions
2. WHEN prerequisites are documented, THEN the system SHALL specify required tools including Terraform 1.5+, GCP account, and gcloud CLI
3. WHEN authentication is documented, THEN the system SHALL explain how to set the GOOGLE_APPLICATION_CREDENTIALS environment variable
4. WHEN usage instructions are provided, THEN the system SHALL include example commands for terraform init, terraform plan, and terraform apply with -chdir flag for each environment
5. WHEN the backend configuration is documented, THEN the system SHALL explain the steps to create a GCS bucket and uncomment the backend.tf configuration
6. WHEN module documentation is provided, THEN the system SHALL describe the purpose and key variables for each of the four modules

### Requirement 10

**User Story:** As a DevOps engineer, I want example tfvars configurations for both dev and prod environments, so that I can test Terraform commands locally and understand how to customize network configurations.

#### Acceptance Criteria

1. WHEN the dev terraform.tfvars is created, THEN the system SHALL include example values for project_id, network_name, region, and zone
2. WHEN the dev terraform.tfvars defines subnets, THEN the system SHALL include at least two example subnets with different regions and CIDR ranges
3. WHEN the dev terraform.tfvars defines firewall rules, THEN the system SHALL include at least two example rules covering both INGRESS and EGRESS directions
4. WHEN the dev terraform.tfvars defines routes, THEN the system SHALL include at least one example custom route
5. WHEN the prod terraform.tfvars is created, THEN the system SHALL include similar structure to dev but with production-appropriate naming and CIDR ranges
6. WHEN example configurations use CIDR ranges, THEN the system SHALL ensure dev and prod use non-overlapping IP address spaces
