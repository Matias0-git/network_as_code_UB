terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  
  # Configuración para trabajar en equipo (Backend)
  backend "gcs" {
    bucket  = "tf-state-network-ub-network-as-code"
    prefix  = "terraform/state"
  }
}

provider "google" {
  project = "network-as-code"
  region  = "us-central1"
}

# --- A partir de aca va su codigo de red ---

# Ejemplo: Una VPC basica para probar
resource "google_compute_network" "vpc_principal" {
  name                    = "vpc-ub-network"
  auto_create_subnetworks = false
}
