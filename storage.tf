# Storage bucket for Terraform state (remote backend)
resource "google_storage_bucket" "terraform_state" {
  name     = "${var.project_id}-${var.environment}-terraform-state"
  project  = var.project_id
  location = var.region

  # Force destroy for development (disable in production)
  force_destroy = var.environment == "dev" ? true : false

  # Enable versioning for state file safety
  versioning {
    enabled = true
  }

  # Uniform bucket-level access for better security
  uniform_bucket_level_access = true

  # Encryption at rest
  #encryption {
  #  default_kms_key_name = null # We'll add KMS in Part 4
  #}

  # Lifecycle management to control costs
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age        = 7
      with_state = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }

  # Labels for resource management
  labels = {
    environment = var.environment
    purpose     = "terraform-state"
    managed-by  = "terraform"
  }
}

# General purpose storage bucket
resource "google_storage_bucket" "app_storage" {
  name     = "${var.project_id}-${var.environment}-app-storage"
  project  = var.project_id
  location = var.region

  # Storage class optimization
  storage_class = "STANDARD"

  uniform_bucket_level_access = true

  # CORS configuration for web applications
  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  labels = {
    environment = var.environment
    purpose     = "application-storage"
    managed-by  = "terraform"
  }
}

# IAM binding for service account access to state bucket
resource "google_storage_bucket_iam_member" "terraform_state_access" {
  bucket = google_storage_bucket.terraform_state.name
  role   = "roles/storage.admin"
  member = "serviceAccount:terraform-automation@${var.project_id}.iam.gserviceaccount.com"
}