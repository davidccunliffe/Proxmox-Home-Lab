resource "proxmox_virtual_environment_vm" "core" {
  depends_on = [
    proxmox_virtual_environment_file.user_config,
    proxmox_virtual_environment_file.vendor_config
  ]

  for_each = local.vms

  name        = each.key
  description = each.value.desc
  node_name   = each.value.pve_node
  on_boot     = try(each.value.autostart, false)
  tags        = sort(concat(["terraform"], [for item in each.value.tags : item]))

  clone {
    vm_id = local.lab.templates[each.value.template].vm_id
    full  = true
  }

  agent {
    enabled = true
  }

  cpu {
    cores   = each.value.cores
    sockets = try(each.value.sockets, 1)
    type    = try(each.value.cpu, "host")
  }

  memory {
    dedicated = each.value.memory
  }

  dynamic "network_device" {
    for_each = each.value.dynamic.networks

    content {
      bridge  = local.networks[network_device.value.net].bridge
      model   = network_device.value.model
      enabled = !network_device.value.link_down
    }
  }

  dynamic "disk" {
    for_each = can(each.value.dynamic.disks) ? {
      for idx, d in each.value.dynamic.disks : idx => d
    } : {}

    content {
      interface    = disk.key
      size         = parseint(replace(disk.value.size, "G", ""), 10)
      datastore_id = disk.value.storage
      file_format  = disk.value.format
      discard      = try(disk.value.discard, null) == "on" ? "on" : "ignore"
    }
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${each.value.dynamic.networks.primary.ip}/24"
        gateway = local.networks[each.value.dynamic.networks.primary.net].gateway
      }
    }

    user_account {
      username = local.lab.ciuser
      keys     = [
        trimspace(data.vault_generic_secret.terraform.data["pm_public_key"]),
        trimspace(data.http.github_ssh_keys.response_body)
      ]
    }

    datastore_id      = try(each.value.cloudinit_storage, "local")
    user_data_file_id = proxmox_virtual_environment_file.user_config[each.key].id
    vendor_data_file_id = proxmox_virtual_environment_file.vendor_config.id
  }

  lifecycle {
    ignore_changes = [
      node_name,
      clone,
    ]
  }
}
