##############################################################################
# Outputs
##############################################################################

output "vm_ids" {
  description = "Proxmox VM IDs of the Bind9 instances"
  value       = proxmox_virtual_environment_vm.bind9[*].vm_id
}

output "hostnames" {
  description = "Hostnames of the Bind9 instances"
  value       = var.hostnames
}

output "ips" {
  description = "IP addresses of the Bind9 instances"
  value       = var.ips
}

output "primary_ip" {
  description = "IP address of the primary DNS server"
  value       = var.ips[0]
}

output "secondary_ip" {
  description = "IP address of the secondary DNS server"
  value       = var.ips[1]
}

output "domain" {
  description = "Internal DNS domain served by this pair"
  value       = var.domain
}
