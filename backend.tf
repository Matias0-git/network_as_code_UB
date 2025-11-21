terraform {
  backend "gcs" {
    # This is the bucket you just created in the last step
    bucket = "network-as-code-dev-terraform-state"
    prefix = "foundation/state"
  }
}