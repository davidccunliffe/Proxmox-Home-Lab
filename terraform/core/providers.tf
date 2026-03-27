terraform {
  required_version = ">= 1.5"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.78"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.6"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
}

provider "proxmox" {
  endpoint = "https://pve-01.lan.pezlab.dev:8006/"
  username = "root@pam"
  password = data.vault_generic_secret.shared.data["root_password"]
  insecure = true
}
