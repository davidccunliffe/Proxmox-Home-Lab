# ------------------------------------------------------------------------------
# Cloud-Init User Data for each Vault node
# ------------------------------------------------------------------------------
# Generates a per-node cloud-init user-data snippet that:
#   - Sets the hostname
#   - Configures static networking (IP, gateway, DNS)
#   - Imports SSH keys from the configured GitHub user
#   - Installs Vault from the HashiCorp APT repository
#   - Writes /etc/vault.d/vault.hcl with Raft HA configuration
#   - Creates and enables a systemd unit for Vault
#
# TLS Note: Vault starts with TLS disabled. An Ansible playbook handles
# initialisation, PKI/ACME setup, certificate generation, and TLS enablement.
# ------------------------------------------------------------------------------

locals {
  # Build the list of all peer nodes for Raft retry_join.
  # Each node gets the full list -- Vault ignores its own address gracefully.
  vault_peers = [for name, node in var.vault_nodes : { name = name, ip = node.ip }]

  # Render the Vault HCL config for each node from the template.
  vault_configs = {
    for name, node in var.vault_nodes : name => templatefile(
      "${path.module}/templates/vault.hcl.tpl",
      {
        node_id  = name
        api_addr = node.ip
        peers    = [for peer in local.vault_peers : peer if peer.name != name]
      }
    )
  }

  # Determine the vault package specifier (pinned version or latest).
  vault_pkg = var.vault_version != "" ? "vault=${var.vault_version}" : "vault"
}

# Cloud-init user-data rendered per node and stored as a Proxmox snippet.
resource "proxmox_virtual_environment_file" "cloud_init_user_data" {
  for_each = var.vault_nodes

  content_type = "snippets"
  datastore_id = "local"
  node_name    = each.value.pve_node

  source_raw {
    data = <<-CLOUDINIT
      #cloud-config
      hostname: ${each.key}
      fqdn: ${each.key}.${var.dns_domain}
      manage_etc_hosts: true

      users:
        - name: ${var.cloud_init_user}
          groups: sudo
          shell: /bin/bash
          sudo: ALL=(ALL) NOPASSWD:ALL
          ssh_import_id:
            - gh:${var.ssh_github_user}

      # ---------------------------------------------------------------
      # Install Vault from the HashiCorp APT repository
      # ---------------------------------------------------------------
      runcmd:
        - |
          # Add the HashiCorp GPG key and APT repository
          apt-get update -y
          apt-get install -y gpg coreutils
          curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
          echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
            > /etc/apt/sources.list.d/hashicorp.list
          apt-get update -y
          apt-get install -y ${local.vault_pkg}

          # Create Raft data directory
          mkdir -p /opt/vault/data
          chown vault:vault /opt/vault/data

          # Write Vault server configuration
          cat > /etc/vault.d/vault.hcl << 'VAULTCFG'
      ${local.vault_configs[each.key]}
      VAULTCFG
          chown vault:vault /etc/vault.d/vault.hcl
          chmod 640 /etc/vault.d/vault.hcl

          # Create systemd service unit
          cat > /etc/systemd/system/vault.service << 'SVCUNIT'
      [Unit]
      Description=HashiCorp Vault
      Documentation=https://developer.hashicorp.com/vault/docs
      Requires=network-online.target
      After=network-online.target
      ConditionFileNotEmpty=/etc/vault.d/vault.hcl

      [Service]
      User=vault
      Group=vault
      ProtectSystem=full
      ProtectHome=read-only
      PrivateTmp=yes
      PrivateDevices=yes
      SecureBits=keep-caps
      AmbientCapabilities=CAP_IPC_LOCK
      CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
      NoNewPrivileges=yes
      ExecStart=/usr/bin/vault server -config=/etc/vault.d/vault.hcl
      ExecReload=/bin/kill --signal HUP $MAINPID
      KillMode=process
      KillSignal=SIGINT
      Restart=on-failure
      RestartSec=5
      TimeoutStopSec=30
      LimitNOFILE=65536
      LimitMEMLOCK=infinity

      [Install]
      WantedBy=multi-user.target
      SVCUNIT

          # Enable and start Vault
          systemctl daemon-reload
          systemctl enable vault
          systemctl start vault
    CLOUDINIT

    file_name = "vault-${each.key}-cloud-init-user-data.yaml"
  }
}
