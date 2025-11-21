# Ingress firewall rule for SSH access
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.environment}-allow-ssh"
  network = google_compute_network.main_vpc.name
  project = var.project_id

  description = "Allow SSH access to instances with ssh-allowed tag"
  direction   = "INGRESS"
  priority    = 1000

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Restrict source ranges for better security
  # For production, use your specific IP ranges
  source_ranges = ["0.0.0.0/0"] # Change this in production!
  target_tags   = ["ssh-allowed"]

  # Log firewall activity
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Ingress firewall rule for HTTP traffic
resource "google_compute_firewall" "allow_http" {
  name    = "${var.environment}-allow-http"
  network = google_compute_network.main_vpc.name
  project = var.project_id

  description = "Allow HTTP access to web servers"
  direction   = "INGRESS"
  priority    = 1000

  allow {
    protocol = "tcp"
    ports    = ["80", "8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Egress firewall rule for internet access
resource "google_compute_firewall" "allow_egress" {
  name    = "${var.environment}-allow-egress"
  network = google_compute_network.main_vpc.name
  project = var.project_id

  description = "Allow outbound internet access"
  direction   = "EGRESS"
  priority    = 1000

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "53"]
  }

  allow {
    protocol = "udp"
    ports    = ["53", "123"]
  }

  destination_ranges = ["0.0.0.0/0"]
  target_tags        = ["ssh-allowed", "http-server"]
}

# Internal communication firewall rule
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.environment}-allow-internal"
  network = google_compute_network.main_vpc.name
  project = var.project_id

  description = "Allow internal communication within VPC"
  direction   = "INGRESS"
  priority    = 1000

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  # Allow traffic from the VPC CIDR
  source_ranges = [var.subnet_cidr, "10.1.0.0/16", "10.2.0.0/16"]
}