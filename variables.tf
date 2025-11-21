variable "project_id" {
  type        = string
  description = "Google Cloud Project ID"
  validation {
    condition     = length(var.project_id) > 6
    error_message = "Project ID must be more than 6 characters."
  }
}

variable "region" {
  type        = string
  description = "GCP region for resources"
  default     = "us-central1"
  validation {
    condition = contains([
      "us-central1", "us-east1", "us-west1", "us-west2",
      "europe-west1", "europe-west2", "asia-east1"
    ], var.region)
    error_message = "Region must be a valid GCP region."
  }
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "vpc_name" {
  type        = string
  description = "Name for the VPC network"
  default     = "main-vpc"
}

variable "subnet_name" {
  type        = string
  description = "Name for the subnet"
  default     = "main-subnet"
}

variable "subnet_cidr" {
  type        = string
  description = "CIDR range for the subnet"
  default     = "10.0.1.0/24"
  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "Subnet CIDR must be a valid IPv4 CIDR block."
  }
}

variable "zone" {
  type        = string
  description = "GCP zone for VM deployment"
  default     = "us-central1-b"
  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]+-[a-z]$", var.zone))
    error_message = "Zone must be a valid GCP zone format (e.g., us-central1-b)."
  }
}

variable "vm_machine_type" {
  type        = string
  description = "Machine type for the VM instance"
  default     = "e2-standard-2"
  validation {
    condition = contains([
      "e2-micro", "e2-small", "e2-medium", "e2-standard-2",
      "e2-standard-4", "n1-standard-1", "n1-standard-2"
    ], var.vm_machine_type)
    error_message = "Machine type must be a valid GCP machine type."
  }
}

variable "prefix" {
  type        = string
  description = "Prefix for resource naming"
  default     = "main"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,10}$", var.prefix))
    error_message = "Prefix must start with a letter, contain only lowercase letters, numbers, and hyphens, and be 2-11 characters long."
  }
}

variable "vm_disk_size" {
  type        = number
  description = "Boot disk size in GB"
  default     = 50
  validation {
    condition     = var.vm_disk_size >= 10 && var.vm_disk_size <= 2000
    error_message = "VM disk size must be between 10 and 2000 GB."
  }
}

variable "vm_image" {
  type        = string
  description = "VM boot disk image"
  default     = "debian-cloud/debian-12"
  validation {
    condition = contains([
      "debian-cloud/debian-12", "ubuntu-os-cloud/ubuntu-2204-lts",
      "centos-cloud/centos-7", "rhel-cloud/rhel-8"
    ], var.vm_image)
    error_message = "VM image must be a supported OS image."
  }
}