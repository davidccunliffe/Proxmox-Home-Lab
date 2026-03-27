terraform {
  required_version = ">= 1.5"

  required_providers {
    netbox = {
      source  = "e-breuninger/netbox"
      version = "~> 3.9"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.6"
    }
  }
}

provider "netbox" {
  server_url           = "https://netbox.lan.pezlab.dev"
  api_token            = data.vault_generic_secret.netbox.data["terraform_key"]
  allow_insecure_https = true
}
