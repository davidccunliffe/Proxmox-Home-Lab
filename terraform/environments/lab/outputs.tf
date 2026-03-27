output "mikrotik_vrrp_vip" {
  description = "MikroTik VRRP virtual IP (default gateway)"
  value       = module.mikrotik.vrrp_vip
}

output "vault_ips" {
  description = "Vault cluster node IPs"
  value       = module.vault.vault_ips
}

output "dns_ips" {
  description = "Bind9 DNS server IPs"
  value       = module.bind9.ips
}

output "k8s_cp_ips" {
  description = "Kubernetes control plane node IPs"
  value       = module.kubernetes.cp_ips
}

output "k8s_worker_ips" {
  description = "Kubernetes worker node IPs"
  value       = module.kubernetes.worker_ips
}

output "k8s_api_endpoint" {
  description = "Kubernetes API endpoint (via MikroTik LB)"
  value       = "https://k8s-api.${var.domain}:6443"
}
