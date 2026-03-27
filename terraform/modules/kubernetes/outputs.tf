##############################################################################
# Control plane outputs
##############################################################################

output "cp_hostnames" {
  description = "Hostnames of the control plane nodes"
  value       = var.cp_hostnames
}

output "cp_ips" {
  description = "IP addresses of the control plane nodes"
  value       = var.cp_ips
}

output "cp_vm_ids" {
  description = "Proxmox VM IDs of the control plane nodes"
  value       = proxmox_virtual_environment_vm.control_plane[*].vm_id
}

##############################################################################
# Worker outputs
##############################################################################

output "worker_hostnames" {
  description = "Hostnames of the worker nodes"
  value       = var.worker_hostnames
}

output "worker_ips" {
  description = "IP addresses of the worker nodes"
  value       = var.worker_ips
}

output "worker_vm_ids" {
  description = "Proxmox VM IDs of the worker nodes"
  value       = proxmox_virtual_environment_vm.worker[*].vm_id
}

##############################################################################
# Cluster-wide outputs
##############################################################################

output "all_hostnames" {
  description = "All node hostnames (control plane + workers)"
  value       = concat(var.cp_hostnames, var.worker_hostnames)
}

output "all_ips" {
  description = "All node IPs (control plane + workers)"
  value       = concat(var.cp_ips, var.worker_ips)
}

output "k8s_api_endpoint" {
  description = "Kubernetes API server endpoint"
  value       = "https://${var.k8s_api_endpoint}:6443"
}

output "pod_cidr" {
  description = "Pod network CIDR (for Calico configuration)"
  value       = var.pod_cidr
}

output "service_cidr" {
  description = "Service network CIDR"
  value       = var.service_cidr
}
