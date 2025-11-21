# Service account for VM instances
resource "google_service_account" "vm_service_account" {
  project      = var.project_id
  account_id   = "${var.prefix}-vm-sa"
  display_name = "VM Service Account for ${var.environment}"
  description  = "Service account for VM instances with minimal required permissions"
}

# IAM roles for VM service account
resource "google_project_iam_member" "vm_sa_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.vm_service_account.email}"
}

resource "google_project_iam_member" "vm_sa_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.vm_service_account.email}"
}

# Compute Engine VM instance
resource "google_compute_instance" "main_vm" {
  name                      = "${var.prefix}-${var.environment}-vm"
  project                   = var.project_id
  machine_type              = var.vm_machine_type
  zone                      = var.zone
  tags                      = ["ssh-allowed", "http-server"]
  allow_stopping_for_update = true

  # Enable deletion protection in production
  deletion_protection = var.environment == "prod" ? true : false

  # Boot disk configuration
  boot_disk {
    initialize_params {
      image = var.vm_image
      type  = "pd-standard"
      size  = var.vm_disk_size
      labels = {
        environment = var.environment
        managed-by  = "terraform"
      }
    }
    auto_delete = true
  }

  # Network configuration - private IP only
  network_interface {
    network    = google_compute_network.main_vpc.self_link
    subnetwork = google_compute_subnetwork.main_subnet.self_link

    # No external IP - will use Cloud NAT for internet access
    # Uncomment below for external IP:
    # access_config {
    #   nat_ip = google_compute_address.vm_external_ip.address
    # }
  }

  # Service account and scopes
  service_account {
    email = google_service_account.vm_service_account.email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write"
    ]
  }

  # Metadata for VM configuration
  metadata = {
    enable-oslogin = "TRUE"
    startup-script = <<-EOF
      #!/bin/bash
      apt-get update
      apt-get install -y nginx
      systemctl start nginx
      systemctl enable nginx
      echo "<h1>Hello from ${var.prefix}-${var.environment}-vm</h1>" > /var/www/html/index.html
      echo "<p>Deployed with Terraform and GitHub Actions</p>" >> /var/www/html/index.html
    EOF
  }

  # Labels for resource management
  labels = {
    environment = var.environment
    managed-by  = "terraform"
    team        = "devops"
  }

  # Depends on the subnet being ready
  depends_on = [
    google_compute_subnetwork.main_subnet
  ]
}

# Optional: Static external IP (commented out for security)
# resource "google_compute_address" "vm_external_ip" {
#   name    = "${var.prefix}-${var.environment}-vm-ip"
#   project = var.project_id
#   region  = var.region
# }