##############################################################################
# Node placement
##############################################################################

variable "nodes" {
  description = "Proxmox node names for each CHR instance"
  type        = list(string)
  default     = ["pve", "pve2"]
}

variable "hostnames" {
  description = "RouterOS identity (hostname) for each CHR instance"
  type        = list(string)
  default     = ["mikrotik-1", "mikrotik-2"]
}

variable "vm_ids" {
  description = "Proxmox VM IDs for each CHR instance (0 = auto-assign)"
  type        = list(number)
  default     = [0, 0]
}

##############################################################################
# CHR disk image
##############################################################################

variable "chr_image" {
  description = "Path to the MikroTik CHR raw disk image on Proxmox storage (e.g. unraidNFS:iso/chr-7.18.img)"
  type        = string
  default     = "unraidNFS:iso/chr-7.18.img"
}

variable "disk_storage" {
  description = "Proxmox storage pool for VM disks"
  type        = string
  default     = "local-zfs"
}

variable "disk_size" {
  description = "Disk size for each CHR VM"
  type        = number
  default     = 1
}

##############################################################################
# VM sizing
##############################################################################

variable "cores" {
  description = "Number of CPU cores per CHR VM"
  type        = number
  default     = 1
}

variable "memory" {
  description = "Memory in MB per CHR VM"
  type        = number
  default     = 512
}

##############################################################################
# Networking - WAN
##############################################################################

variable "wan_bridge" {
  description = "Proxmox bridge for the WAN interface (ether1)"
  type        = string
  default     = "vmbr0"
}

##############################################################################
# Networking - LAN
##############################################################################

variable "lan_bridge" {
  description = "Proxmox bridge for the LAN interface (ether2)"
  type        = string
  default     = "vmbr2"
}

variable "lan_ips" {
  description = "LAN IP addresses for each CHR instance (without CIDR)"
  type        = list(string)
  default     = ["172.16.0.2", "172.16.0.3"]
}

variable "lan_cidr" {
  description = "CIDR prefix length for the LAN network"
  type        = number
  default     = 16
}

##############################################################################
# VRRP
##############################################################################

variable "vrrp_vip" {
  description = "VRRP virtual IP address shared between CHR instances (LAN gateway)"
  type        = string
  default     = "172.16.0.1"
}

variable "vrrp_priorities" {
  description = "VRRP priority for each CHR instance (higher = master)"
  type        = list(number)
  default     = [150, 100]
}

##############################################################################
# DNS
##############################################################################

variable "dns_servers" {
  description = "Comma-separated upstream DNS servers for RouterOS"
  type        = string
  default     = "1.1.1.1,8.8.8.8"
}

##############################################################################
# Kubernetes API load balancing
##############################################################################

variable "k8s_cp_ips" {
  description = "IP addresses of Kubernetes control plane nodes for API load balancing"
  type        = list(string)
  default     = ["172.16.1.10", "172.16.1.11", "172.16.1.12"]
}

variable "k8s_api_port" {
  description = "Kubernetes API server port"
  type        = number
  default     = 6443
}

##############################################################################
# Tags
##############################################################################

variable "tags" {
  description = "Tags to apply to the Proxmox VMs"
  type        = list(string)
  default     = ["mikrotik", "router", "terraform"]
}
