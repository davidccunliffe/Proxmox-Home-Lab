##############################################################################
# Cloud-init template
##############################################################################

variable "template_id" {
  description = "VM ID of the Ubuntu 24.04 cloud-init template to clone"
  type        = number
}

variable "template_node" {
  description = "Proxmox node where the template resides (used for clone source)"
  type        = string
  default     = "pve"
}

##############################################################################
# Control plane nodes
##############################################################################

variable "cp_count" {
  description = "Number of control plane nodes"
  type        = number
  default     = 3
}

variable "cp_hostnames" {
  description = "Hostnames for control plane nodes"
  type        = list(string)
  default     = ["k8s-cp-1", "k8s-cp-2", "k8s-cp-3"]
}

variable "cp_nodes" {
  description = "Proxmox nodes to place each control plane VM on"
  type        = list(string)
  default     = ["pve", "pve2", "pve3"]
}

variable "cp_vm_ids" {
  description = "Proxmox VM IDs for control plane nodes (0 = auto-assign)"
  type        = list(number)
  default     = [0, 0, 0]
}

variable "cp_ips" {
  description = "Static IP addresses for control plane nodes (without CIDR)"
  type        = list(string)
  default     = ["172.16.1.10", "172.16.1.11", "172.16.1.12"]
}

variable "cp_cores" {
  description = "Number of CPU cores per control plane VM"
  type        = number
  default     = 4
}

variable "cp_memory" {
  description = "Memory in MB per control plane VM"
  type        = number
  default     = 8192
}

variable "cp_disk_size" {
  description = "OS disk size in GB for control plane nodes"
  type        = number
  default     = 40
}

##############################################################################
# Worker nodes
##############################################################################

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 3
}

variable "worker_hostnames" {
  description = "Hostnames for worker nodes"
  type        = list(string)
  default     = ["k8s-worker-1", "k8s-worker-2", "k8s-worker-3"]
}

variable "worker_nodes" {
  description = "Proxmox nodes to place each worker VM on"
  type        = list(string)
  default     = ["pve2", "pve3", "pve4"]
}

variable "worker_vm_ids" {
  description = "Proxmox VM IDs for worker nodes (0 = auto-assign)"
  type        = list(number)
  default     = [0, 0, 0]
}

variable "worker_ips" {
  description = "Static IP addresses for worker nodes (without CIDR)"
  type        = list(string)
  default     = ["172.16.1.20", "172.16.1.21", "172.16.1.22"]
}

variable "worker_cores" {
  description = "Number of CPU cores per worker VM"
  type        = number
  default     = 4
}

variable "worker_memory" {
  description = "Memory in MB per worker VM"
  type        = number
  default     = 16384
}

variable "worker_disk_size" {
  description = "OS disk size in GB for worker nodes"
  type        = number
  default     = 80
}

##############################################################################
# Networking
##############################################################################

variable "network_bridge" {
  description = "Proxmox bridge for the VM network interface"
  type        = string
  default     = "vmbr2"
}

variable "ip_cidr" {
  description = "CIDR prefix length for node IPs"
  type        = number
  default     = 16
}

variable "gateway" {
  description = "Default gateway (MikroTik VRRP VIP)"
  type        = string
  default     = "172.16.0.1"
}

variable "dns_servers" {
  description = "DNS server addresses"
  type        = list(string)
  default     = ["172.16.0.20", "172.16.0.21"]
}

variable "dns_domain" {
  description = "DNS search domain"
  type        = string
  default     = "lab.davidccunliffe.pro"
}

##############################################################################
# Storage
##############################################################################

variable "disk_storage" {
  description = "Proxmox storage pool for VM disks"
  type        = string
  default     = "local-zfs"
}

variable "disk_format" {
  description = "Disk format (raw, qcow2)"
  type        = string
  default     = "raw"
}

##############################################################################
# Kubernetes
##############################################################################

variable "k8s_version" {
  description = "Kubernetes minor version to install (e.g. 1.32)"
  type        = string
  default     = "1.32"
}

variable "k8s_api_endpoint" {
  description = "Kubernetes API server endpoint FQDN (load balanced)"
  type        = string
  default     = "k8s-api.lab.davidccunliffe.pro"
}

variable "pod_cidr" {
  description = "Pod network CIDR (Calico)"
  type        = string
  default     = "10.244.0.0/16"
}

variable "service_cidr" {
  description = "Service network CIDR"
  type        = string
  default     = "10.96.0.0/12"
}

##############################################################################
# Cloud-init
##############################################################################

variable "github_user" {
  description = "GitHub username to import SSH public keys from"
  type        = string
  default     = "davidccunliffe"
}

variable "default_user" {
  description = "Default user created by cloud-init"
  type        = string
  default     = "ubuntu"
}

##############################################################################
# Tags
##############################################################################

variable "cp_tags" {
  description = "Tags to apply to control plane VMs"
  type        = list(string)
  default     = ["kubernetes", "control-plane", "terraform"]
}

variable "worker_tags" {
  description = "Tags to apply to worker VMs"
  type        = list(string)
  default     = ["kubernetes", "worker", "terraform"]
}
