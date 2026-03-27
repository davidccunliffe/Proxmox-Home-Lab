##############################################################################
# Node placement
##############################################################################

variable "nodes" {
  description = "Proxmox node names for each Bind9 instance"
  type        = list(string)
  default     = ["pve3", "pve4"]
}

variable "hostnames" {
  description = "Hostnames for each Bind9 instance"
  type        = list(string)
  default     = ["dns-1", "dns-2"]
}

variable "vm_ids" {
  description = "Proxmox VM IDs for each Bind9 instance (0 = auto-assign)"
  type        = list(number)
  default     = [0, 0]
}

##############################################################################
# Clone source
##############################################################################

variable "template_id" {
  description = "VM ID of the Ubuntu 24.04 cloud-init template to clone"
  type        = number
}

variable "template_node" {
  description = "Proxmox node where the template resides"
  type        = string
  default     = "pve3"
}

##############################################################################
# VM sizing
##############################################################################

variable "cores" {
  description = "Number of CPU cores per Bind9 VM"
  type        = number
  default     = 1
}

variable "memory" {
  description = "Memory in MB per Bind9 VM"
  type        = number
  default     = 2048
}

##############################################################################
# Storage
##############################################################################

variable "disk_storage" {
  description = "Proxmox storage pool for VM disks"
  type        = string
  default     = "local-zfs"
}

variable "disk_size" {
  description = "OS disk size in GB"
  type        = number
  default     = 10
}

variable "disk_format" {
  description = "Disk image format"
  type        = string
  default     = "raw"
}

##############################################################################
# Networking
##############################################################################

variable "bridge" {
  description = "Proxmox bridge for the VM network interface"
  type        = string
  default     = "vmbr2"
}

variable "ips" {
  description = "Static IP addresses for each Bind9 instance (without CIDR)"
  type        = list(string)
  default     = ["172.16.0.20", "172.16.0.21"]
}

variable "cidr" {
  description = "CIDR prefix length for the network"
  type        = number
  default     = 16
}

variable "gateway" {
  description = "Default gateway (MikroTik VRRP VIP)"
  type        = string
  default     = "172.16.0.1"
}

variable "nameservers" {
  description = "DNS servers for cloud-init resolv.conf (pointed at themselves once running)"
  type        = list(string)
  default     = ["172.16.0.20", "172.16.0.21"]
}

##############################################################################
# DNS configuration
##############################################################################

variable "domain" {
  description = "Internal DNS domain"
  type        = string
  default     = "lab.davidccunliffe.pro"
}

variable "forwarders" {
  description = "Upstream DNS forwarders"
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
}

variable "dns_records" {
  description = "A-record map: hostname -> list of IPs (multiple IPs = round-robin)"
  type        = map(list(string))
  default = {
    "mikrotik-1"   = ["172.16.0.2"]
    "mikrotik-2"   = ["172.16.0.3"]
    "gateway"      = ["172.16.0.1"]
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

variable "reverse_zone_network" {
  description = "Network prefix for reverse DNS zone (in-addr.arpa notation, e.g. 16.172)"
  type        = string
  default     = "16.172"
}

variable "zone_serial" {
  description = "SOA serial number for zone files (YYYYMMDDNN format recommended)"
  type        = string
  default     = "2026032701"
}

##############################################################################
# Cloud-init user
##############################################################################

variable "ci_user" {
  description = "Default user created by cloud-init"
  type        = string
  default     = "ubuntu"
}

variable "ci_ssh_keys" {
  description = "List of SSH public keys to inject via cloud-init"
  type        = list(string)
  default     = []
}

##############################################################################
# Tags
##############################################################################

variable "tags" {
  description = "Tags to apply to the Proxmox VMs"
  type        = list(string)
  default     = ["bind9", "dns", "terraform"]
}
