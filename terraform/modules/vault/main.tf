# ------------------------------------------------------------------------------
# Vault HA Cluster - VM Resources (Proxmox VE 9.1)
# ------------------------------------------------------------------------------
# Deploys a 3-node HashiCorp Vault cluster using integrated Raft storage.
# Each node is cloned from a Packer-built Ubuntu 24.04 cloud-init template
# and placed on a separate Proxmox host for high availability.
#
# Post-deployment workflow (handled by Ansible):
#   1. Initialize Vault on vault-1, unseal all three nodes
#   2. Enable PKI secrets engine as the Private CA
#   3. Configure ACME support on the PKI engine
#   4. Issue TLS certificates for each Vault node
#   5. Update vault.hcl to enable TLS on the listener
#   6. Restart Vault cluster with TLS enabled
# ------------------------------------------------------------------------------

resource "proxmox_virtual_environment_vm" "vault" {
  for_each = var.vault_nodes

  name      = each.key
  node_name = each.value.pve_node
  vm_id     = each.value.vm_id
  tags      = var.tags

  description = "Vault HA node (Raft) - Managed by Terraform"

  # Clone from the Packer-built Ubuntu 24.04 cloud-init template.
  clone {
    vm_id = var.template_vm_id
    full  = true
  }

  # --- Compute -----------------------------------------------------------
  cpu {
    cores = var.cpu_cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.memory
  }

  # --- Storage -----------------------------------------------------------
  disk {
    datastore_id = var.disk_datastore
    interface    = "scsi0"
    size         = var.disk_size
    file_format  = var.disk_format
  }

  # --- Networking --------------------------------------------------------
  network_device {
    bridge = var.network_bridge
  }

  # --- Cloud-Init --------------------------------------------------------
  initialization {
    ip_config {
      ipv4 {
        address = "${each.value.ip}/${var.subnet_mask}"
        gateway = var.gateway
      }
    }

    dns {
      servers = var.dns_servers
      domain  = var.dns_domain
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_init_user_data[each.key].id
  }

  # --- Guest Agent -------------------------------------------------------
  agent {
    enabled = true
  }

  # Ensure cloud-init completes before Terraform marks the resource ready.
  lifecycle {
    ignore_changes = [
      # The cloud-init disk is regenerated on every apply; ignore drift.
      initialization,
    ]
  }
}
