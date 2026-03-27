# ------------------------------------------------------------------------------
# Vault HA Cluster - Outputs
# ------------------------------------------------------------------------------

output "vault_ips" {
  description = "Map of Vault node names to their IP addresses."
  value       = { for name, node in var.vault_nodes : name => node.ip }
}

output "vault_hostnames" {
  description = "Map of Vault node names to their FQDN."
  value       = { for name, node in var.vault_nodes : name => "${name}.${var.dns_domain}" }
}

output "vault_vm_ids" {
  description = "Map of Vault node names to their Proxmox VM IDs."
  value       = { for name, vm in proxmox_virtual_environment_vm.vault : name => vm.vm_id }
}

output "vault_api_addresses" {
  description = "Map of Vault node names to their API endpoint URLs."
  value       = { for name, node in var.vault_nodes : name => "http://${node.ip}:8200" }
}
