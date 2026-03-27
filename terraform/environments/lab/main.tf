#===============================================================================
# Lab Environment - Module Composition
#
# Deploys all infrastructure in the correct dependency order:
#   1. MikroTik CHR VRRP pair (gateway/firewall)
#   2. Vault HA cluster (secrets + PKI CA)
#   3. Bind9 HA DNS servers
#   4. Kubernetes cluster (3 CP + 3 workers with Calico)
#===============================================================================

data "http" "github_ssh_keys" {
  url = "https://github.com/${var.github_username}.keys"
}

locals {
  ssh_public_keys = split("\n", trimspace(data.http.github_ssh_keys.response_body))
}

#---------------------------------------------------------------
# Stage 1: Network Gateway
#---------------------------------------------------------------
module "mikrotik" {
  source = "../../modules/mikrotik"

  # Node placement (defaults: ["pve", "pve2"])
  # Hostnames (defaults: ["mikrotik-1", "mikrotik-2"])
  # WAN bridge (default: vmbr0), LAN bridge (default: vmbr2)
  # VRRP VIP (default: 172.16.0.1)
  # LAN IPs (defaults: ["172.16.0.2", "172.16.0.3"])
  # VRRP priorities (defaults: [150, 100])

  chr_image   = var.chr_image
  dns_servers = "172.16.0.20,172.16.0.21"
  k8s_cp_ips  = ["172.16.1.10", "172.16.1.11", "172.16.1.12"]
}

#---------------------------------------------------------------
# Stage 2: Secrets & PKI
#---------------------------------------------------------------
module "vault" {
  source     = "../../modules/vault"
  depends_on = [module.mikrotik]

  template_vm_id = var.template_vm_id
  dns_domain     = var.domain

  # vault_nodes uses defaults: vault-1 on pve (.10), vault-2 on pve2 (.11), vault-3 on pve3 (.12)
  # network_bridge defaults to vmbr2
  # gateway defaults to 172.16.0.1
  # dns_servers defaults to [172.16.0.20, 172.16.0.21]
  # ssh_github_user defaults to davidccunliffe
}

#---------------------------------------------------------------
# Stage 3: DNS
#---------------------------------------------------------------
module "bind9" {
  source     = "../../modules/bind9"
  depends_on = [module.mikrotik]

  template_id = var.template_vm_id
  ci_ssh_keys = local.ssh_public_keys
  domain      = var.domain

  # nodes defaults to ["pve3", "pve4"]
  # hostnames defaults to ["dns-1", "dns-2"]
  # ips defaults to ["172.16.0.20", "172.16.0.21"]
  # bridge defaults to vmbr2
  # gateway defaults to 172.16.0.1
  # dns_records has sensible defaults for all infrastructure

  dns_records = {
    "gateway"      = ["172.16.0.1"]
    "mikrotik-1"   = ["172.16.0.2"]
    "mikrotik-2"   = ["172.16.0.3"]
    "vault-1"      = ["172.16.0.10"]
    "vault-2"      = ["172.16.0.11"]
    "vault-3"      = ["172.16.0.12"]
    "vault"        = ["172.16.0.10", "172.16.0.11", "172.16.0.12"]
    "dns-1"        = ["172.16.0.20"]
    "dns-2"        = ["172.16.0.21"]
    "k8s-cp-1"     = ["172.16.1.10"]
    "k8s-cp-2"     = ["172.16.1.11"]
    "k8s-cp-3"     = ["172.16.1.12"]
    "k8s-worker-1" = ["172.16.1.20"]
    "k8s-worker-2" = ["172.16.1.21"]
    "k8s-worker-3" = ["172.16.1.22"]
    "k8s-api"      = ["172.16.0.1"]
  }
}

#---------------------------------------------------------------
# Stage 4: Kubernetes
#---------------------------------------------------------------
module "kubernetes" {
  source     = "../../modules/kubernetes"
  depends_on = [module.mikrotik, module.bind9]

  template_id      = var.template_vm_id
  k8s_api_endpoint = "k8s-api.${var.domain}"

  # Control plane defaults: k8s-cp-{1,2,3} on pve/pve2/pve3 at 172.16.1.{10,11,12}
  # Worker defaults: k8s-worker-{1,2,3} on pve2/pve3/pve4 at 172.16.1.{20,21,22}
  # network_bridge defaults to vmbr2
  # gateway defaults to 172.16.0.1
  # dns_servers defaults to [172.16.0.20, 172.16.0.21]
  # dns_domain defaults to lab.davidccunliffe.pro
  # pod_cidr defaults to 10.244.0.0/16
  # service_cidr defaults to 10.96.0.0/12
  # github_user defaults to davidccunliffe
}
