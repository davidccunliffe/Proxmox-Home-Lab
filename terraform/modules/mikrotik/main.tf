##############################################################################
# MikroTik CHR VRRP Pair
#
# Deploys two MikroTik Cloud Hosted Router VMs across Proxmox nodes with
# VRRP high availability on the LAN side.  The CHR pair serves as the
# gateway, NAT, firewall, and K8s API load balancer for the internal
# 172.16.0.0/16 network.
#
# NOTE: MikroTik CHR does not support cloud-init.  After first boot the
# rendered RouterOS configuration script must be applied manually via
# the RouterOS terminal, Winbox, or the MikroTik REST/API.  Rendered
# scripts are written to local disk by the local_file resources below.
##############################################################################

locals {
  instances = [
    for i in range(length(var.nodes)) : {
      index         = i
      hostname      = var.hostnames[i]
      node          = var.nodes[i]
      vm_id         = var.vm_ids[i]
      lan_ip        = var.lan_ips[i]
      vrrp_priority = var.vrrp_priorities[i]
    }
  ]
}

# ---------------------------------------------------------------------------
# CHR Virtual Machines
# ---------------------------------------------------------------------------

resource "proxmox_virtual_environment_vm" "mikrotik" {
  for_each = { for inst in local.instances : inst.hostname => inst }

  name        = each.value.hostname
  node_name   = each.value.node
  vm_id       = each.value.vm_id != 0 ? each.value.vm_id : null
  description = "MikroTik CHR - VRRP ${each.value.vrrp_priority == max(var.vrrp_priorities...) ? "master" : "backup"}"
  tags        = var.tags
  on_boot     = true
  started     = true

  bios       = "seabios"
  machine    = "q35"
  os_type    = "l26"

  cpu {
    cores = var.cores
    type  = "host"
  }

  memory {
    dedicated = var.memory
  }

  agent {
    enabled = false
  }

  # ether1 - WAN (DHCP from upstream router on 192.168.189.0/22)
  network_device {
    bridge = var.wan_bridge
    model  = "virtio"
  }

  # ether2 - LAN (internal VM network 172.16.0.0/16)
  network_device {
    bridge = var.lan_bridge
    model  = "virtio"
  }

  # CHR raw disk image - imported from pre-uploaded image
  disk {
    datastore_id = var.disk_storage
    file_id      = var.chr_image
    interface    = "virtio0"
    size         = var.disk_size
    file_format  = "raw"
  }

  boot_order = ["virtio0"]

  # Prevent Terraform from recreating VMs when the image checksum changes
  lifecycle {
    ignore_changes = [
      disk[0].file_id,
    ]
  }
}

# ---------------------------------------------------------------------------
# Rendered RouterOS configuration scripts
# ---------------------------------------------------------------------------

resource "local_file" "mikrotik_config" {
  for_each = { for inst in local.instances : inst.hostname => inst }

  filename        = "${path.module}/files/rendered/${each.value.hostname}-config.rsc"
  file_permission = "0640"

  content = templatefile("${path.module}/files/mikrotik-config.rsc.tpl", {
    hostname      = each.value.hostname
    lan_ip        = each.value.lan_ip
    lan_cidr      = var.lan_cidr
    vrrp_priority = each.value.vrrp_priority
    vrrp_vip      = var.vrrp_vip
    dns_servers   = var.dns_servers
    k8s_api_port  = var.k8s_api_port
    k8s_cp_1      = var.k8s_cp_ips[0]
    k8s_cp_2      = var.k8s_cp_ips[1]
    k8s_cp_3      = var.k8s_cp_ips[2]
  })
}
