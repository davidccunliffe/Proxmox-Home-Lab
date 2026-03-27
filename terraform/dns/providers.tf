terraform {
  required_version = ">= 1.5"

  required_providers {
    powerdns = {
      source  = "pan-net/powerdns"
      version = "~> 1.5"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.6"
    }
  }
}

provider "powerdns" {
  api_key        = data.vault_generic_secret.pdns.data["terraform_key"]
  server_url     = "https://10.0.0.241"
  insecure_https = true
}

provider "powerdns" {
  api_key        = data.vault_generic_secret.pdns.data["terraform_key"]
  server_url     = "https://10.0.0.242"
  insecure_https = true
  alias          = "secondary"
}
