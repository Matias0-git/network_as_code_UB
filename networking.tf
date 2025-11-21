# VPC Network
resource "google_compute_network" "main_vpc" {
  name                    = "${var.environment}-${var.vpc_name}"
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  mtu                     = 1460

  description = "Main VPC network for ${var.environment} environment"

  # Enable deletion protection in production
  delete_default_routes_on_create = false
}

# Subnet
resource "google_compute_subnetwork" "main_subnet" {
  name                     = "${var.environment}-${var.subnet_name}"
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.main_vpc.name
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true

  description = "Primary subnet in ${var.region} for ${var.environment}"

  # Enable flow logs for security monitoring
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }

  # Secondary IP ranges for future use (GKE, etc.)
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.2.0.0/16"
  }
}

# Cloud Router for Cloud NAT (we'll use this in Part 2)
resource "google_compute_router" "main_router" {
  name    = "${var.environment}-cloud-router"
  project = var.project_id
  region  = var.region
  network = google_compute_network.main_vpc.id

  description = "Cloud Router for NAT gateway"
}

# Cloud NAT for private VM internet access
resource "google_compute_router_nat" "main_nat" {
  name   = "${var.environment}-nat-gateway"
  router = google_compute_router.main_router.name
  region = var.region

  # NAT IP allocation
  nat_ip_allocate_option = "AUTO_ONLY"

  # Which subnets to provide NAT for
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.main_subnet.name
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  # Logging for monitoring
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }

  # Timeout settings
  min_ports_per_vm                 = 64
  udp_idle_timeout_sec             = 30
  icmp_idle_timeout_sec            = 30
  tcp_established_idle_timeout_sec = 1200
  tcp_transitory_idle_timeout_sec  = 30
}