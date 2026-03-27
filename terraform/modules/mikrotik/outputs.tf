output "vrrp_vip" {
  description = "VRRP virtual IP address (LAN gateway for all VMs)"
  value       = var.vrrp_vip
}

output "wan_ips" {
  description = "WAN IP addresses assigned by DHCP (available after boot, read from QEMU agent - may be empty since agent is disabled)"
  value = {
    for hostname, vm in proxmox_virtual_environment_vm.mikrotik :
    hostname => "DHCP (check RouterOS after boot)"
  }
}

output "lan_ips" {
  description = "LAN IP addresses for each CHR instance"
  value = {
    for inst in local.instances :
    inst.hostname => inst.lan_ip
  }
}

output "vm_ids" {
  description = "Proxmox VM IDs for each CHR instance"
  value = {
    for hostname, vm in proxmox_virtual_environment_vm.mikrotik :
    hostname => vm.vm_id
  }
}

output "rendered_config_paths" {
  description = "Paths to the rendered RouterOS configuration scripts (apply manually after first boot)"
  value = {
    for hostname, cfg in local_file.mikrotik_config :
    hostname => cfg.filename
  }
}
