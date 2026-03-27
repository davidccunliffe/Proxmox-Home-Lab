##############################################################################
# Control plane VMs
##############################################################################

resource "proxmox_virtual_environment_vm" "control_plane" {
  count = var.cp_count

  name      = var.cp_hostnames[count.index]
  node_name = var.cp_nodes[count.index]
  vm_id     = var.cp_vm_ids[count.index] != 0 ? var.cp_vm_ids[count.index] : null
  tags      = var.cp_tags
  on_boot   = true

  clone {
    vm_id     = var.template_id
    node_name = var.template_node
    full      = true
  }

  cpu {
    cores = var.cp_cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.cp_memory
  }

  agent {
    enabled = true
  }

  disk {
    datastore_id = var.disk_storage
    interface    = "scsi0"
    size         = var.cp_disk_size
    file_format  = var.disk_format
    discard      = "on"
    iothread     = true
    ssd          = true
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  initialization {
    datastore_id      = var.disk_storage
    user_data_file_id = proxmox_virtual_environment_file.cloud_init_cp[count.index].id

    ip_config {
      ipv4 {
        address = "${var.cp_ips[count.index]}/${var.ip_cidr}"
        gateway = var.gateway
      }
    }

    dns {
      servers = var.dns_servers
      domain  = var.dns_domain
    }
  }

  lifecycle {
    ignore_changes = [
      clone,
      disk[0].size,
    ]
  }
}

##############################################################################
# Worker VMs
##############################################################################

resource "proxmox_virtual_environment_vm" "worker" {
  count = var.worker_count

  name      = var.worker_hostnames[count.index]
  node_name = var.worker_nodes[count.index]
  vm_id     = var.worker_vm_ids[count.index] != 0 ? var.worker_vm_ids[count.index] : null
  tags      = var.worker_tags
  on_boot   = true

  clone {
    vm_id     = var.template_id
    node_name = var.template_node
    full      = true
  }

  cpu {
    cores = var.worker_cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.worker_memory
  }

  agent {
    enabled = true
  }

  disk {
    datastore_id = var.disk_storage
    interface    = "scsi0"
    size         = var.worker_disk_size
    file_format  = var.disk_format
    discard      = "on"
    iothread     = true
    ssd          = true
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  initialization {
    datastore_id      = var.disk_storage
    user_data_file_id = proxmox_virtual_environment_file.cloud_init_worker[count.index].id

    ip_config {
      ipv4 {
        address = "${var.worker_ips[count.index]}/${var.ip_cidr}"
        gateway = var.gateway
      }
    }

    dns {
      servers = var.dns_servers
      domain  = var.dns_domain
    }
  }

  lifecycle {
    ignore_changes = [
      clone,
      disk[0].size,
    ]
  }
}
