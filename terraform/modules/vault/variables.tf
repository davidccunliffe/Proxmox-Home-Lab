# ------------------------------------------------------------------------------
# Vault HA Cluster - Input Variables
# ------------------------------------------------------------------------------

variable "vault_nodes" {
  description = "Map of Vault node configurations. Key is the node name (e.g. vault-1)."
  type = map(object({
    pve_node = string
    ip       = string
    vm_id    = optional(number)
  }))
  default = {
    "vault-1" = {
      pve_node = "pve"
      ip       = "172.16.0.10"
      vm_id    = 4010
    }
    "vault-2" = {
      pve_node = "pve2"
      ip       = "172.16.0.11"
      vm_id    = 4011
    }
    "vault-3" = {
      pve_node = "pve3"
      ip       = "172.16.0.12"
      vm_id    = 4012
    }
  }
}

variable "template_vm_id" {
  description = "VM ID of the Packer-built Ubuntu 24.04 cloud-init template to clone from."
  type        = number
}

variable "cpu_cores" {
  description = "Number of CPU cores per Vault VM."
  type        = number
  default     = 2
}

variable "memory" {
  description = "Memory in MB per Vault VM."
  type        = number
  default     = 4096
}

variable "disk_size" {
  description = "OS disk size in GB."
  type        = number
  default     = 20
}

variable "disk_datastore" {
  description = "Proxmox datastore for the OS disk."
  type        = string
  default     = "local-zfs"
}

variable "disk_format" {
  description = "Disk image format."
  type        = string
  default     = "raw"
}

variable "network_bridge" {
  description = "Network bridge for the Vault VLAN."
  type        = string
  default     = "vmbr2"
}

variable "subnet_mask" {
  description = "Subnet mask in CIDR prefix length."
  type        = number
  default     = 16
}

variable "gateway" {
  description = "Default gateway (MikroTik VRRP VIP)."
  type        = string
  default     = "172.16.0.1"
}

variable "dns_servers" {
  description = "DNS server addresses (Bind9 resolvers)."
  type        = list(string)
  default     = ["172.16.0.20", "172.16.0.21"]
}

variable "dns_domain" {
  description = "DNS search domain."
  type        = string
  default     = "lab.davidccunliffe.pro"
}

variable "ssh_github_user" {
  description = "GitHub username whose public keys will be imported for SSH access."
  type        = string
  default     = "davidccunliffe"
}

variable "vault_version" {
  description = "Vault version to install. Leave empty to install the latest from the HashiCorp repo."
  type        = string
  default     = ""
}

variable "cloud_init_user" {
  description = "Default user created by cloud-init."
  type        = string
  default     = "ubuntu"
}

variable "tags" {
  description = "Tags to apply to each Vault VM in Proxmox."
  type        = list(string)
  default     = ["vault", "ubuntu"]
}
