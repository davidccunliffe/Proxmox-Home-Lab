##############################################################################
# Bind9 HA DNS pair - Proxmox VE VMs
##############################################################################

resource "proxmox_virtual_environment_vm" "bind9" {
  count = length(var.hostnames)

  name      = var.hostnames[count.index]
  node_name = var.nodes[count.index]
  vm_id     = var.vm_ids[count.index] != 0 ? var.vm_ids[count.index] : null
  tags      = var.tags

  clone {
    vm_id = var.template_id
  }

  cpu {
    cores = var.cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.memory
  }

  agent {
    enabled = true
  }

  disk {
    datastore_id = var.disk_storage
    interface    = "scsi0"
    size         = var.disk_size
    file_format  = var.disk_format
  }

  network_device {
    bridge = var.bridge
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${var.ips[count.index]}/${var.cidr}"
        gateway = var.gateway
      }
    }

    dns {
      servers = var.nameservers
      domain  = var.domain
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_init[count.index].id
  }

  lifecycle {
    ignore_changes = [
      disk[0].size,
    ]
  }
}
