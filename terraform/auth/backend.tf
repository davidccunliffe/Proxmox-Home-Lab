terraform {
  backend "s3" {
    bucket = "pve-homelab-7ae2"
    endpoints = {
      s3 = "https://s3.us-central-1.wasabisys.com"
    }
    key                         = "auth-terraform.tfstate"
    region                      = "us-central-1"
    use_path_style              = true
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
  }
}
