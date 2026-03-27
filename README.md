# Proxmox-Home-Lab

Packer, Terraform, and Ansible code to run a four node clustered Proxmox Home Lab running **Proxmox VE 9.1**.

## Architecture

```
                     +-----------+
                     |  Wasabi   |
                     | S3 State  |
                     +-----+-----+
                           |
     +----------+----------+----------+----------+
     |          |          |          |          |
  +--v---+  +--v---+  +--v---+  +--v---+  +---------+
  | pve  |  | pve2 |  | pve3 |  | pve4 |  | Unraid  |
  |.0.10 |  |.0.20 |  |.0.30 |  |.0.40 |  | NFS/SMB |
  +------+  +------+  +------+  +------+  +---------+
     |          |          |          |          |
     +----------+----------+----------+----------+
                    Cluster (corosync)
```

### Cluster Nodes

| Node | Management IP     | Internal IP | Bonds          |
|------|-------------------|-------------|----------------|
| pve  | 192.168.189.10/22 | 10.0.0.10/22| bond0, bond1  |
| pve2 | 192.168.189.20/22 | 10.0.0.20/22| bond0, bond1  |
| pve3 | 192.168.189.30/22 | 10.0.0.30/22| bond0, bond1  |
| pve4 | 192.168.189.40/22 | 10.0.0.40/22| bond0, bond1  |

### Network Layout

| Network    | Bridge | Subnet             | Bond  | Purpose                |
|------------|--------|--------------------|-------|------------------------|
| Management | vmbr0  | 192.168.189.0/22   | bond0 | Management + VM access |
| Internal   | vmbr1  | 10.0.0.0/22        | bond1 | Cluster + storage      |

### Deployed VMs

| VM ID | VM Name  | Role            | Node | Cores | RAM    | Storage    |
|-------|----------|-----------------|------|-------|--------|------------|
| 1000  | Windows  | Windows Server  | pve  | 4     | 8 GB   | unraidNFS  |

## Requirements

### Lab Servers (4x bare metal)

Proxmox VE is a **bare-metal hypervisor** — it installs directly onto your servers as its own OS (based on Debian). You do not install it on top of another operating system. Download the [Proxmox VE 9.x ISO](https://www.proxmox.com/en/downloads) and boot each server from it.

### Workstation (where you run the automation)

You need a machine to execute Packer, Terraform, and Ansible against the Proxmox API. This can be **Linux, macOS, or Windows (via WSL)** — any OS that supports the tools below:

* [Packer](https://www.packer.io/) >= 1.11
* [Terraform](https://www.terraform.io/) >= 1.5
* [Ansible](https://www.ansible.com/)
* [HashiCorp Vault CLI](https://www.vaultproject.io/)
* [Python 3](https://www.python.org/) + [Proxmoxer Library](https://pypi.org/project/proxmoxer/)

### Terraform Providers

| Provider                | Version | Purpose                     |
|-------------------------|---------|-----------------------------|
| bpg/proxmox             | ~> 0.78 | Proxmox VE management       |
| hashicorp/vault         | ~> 4.6  | Secrets management           |
| pan-net/powerdns        | ~> 1.5  | DNS record management        |
| e-breuninger/netbox     | ~> 3.9  | IPAM/DCIM tracking          |
| mrparkers/keycloak      | ~> 4.4  | SSO/Identity management      |
| rework-space-com/freeipa| ~> 4.1  | LDAP/Directory services      |

## Assumptions

Four node Proxmox VE 9.x cluster with bonded NICs and shared storage via Unraid (NFS/CIFS). If you already have Proxmox installed and clustered, skip to the step in the [Order of Operations](#order-of-operations) that matches your current state.

### Automation and Responsibilities

**Ansible** handles:
- Cloud image creation
- Proxmox network/VLAN setup
- Post-deployment software installation/configuration

**Terraform** handles:
- VM deployment via cloud-init (bpg/proxmox provider)
- Proxmox cluster configuration (pools, roles, users, timezones)
- DNS management (PowerDNS zones and records)
- Netbox IPAM/DCIM inventory
- Keycloak realm and LDAP federation
- FreeIPA user/group management

**Packer** handles:
- Ubuntu 24.04 LTS VM template creation across all nodes

## Project Structure

```
.
├── packer/
│   ├── ubuntu22_04/          # Legacy Ubuntu 22.04 templates
│   └── ubuntu24_04/          # Ubuntu 24.04 LTS templates (current)
│       ├── ubuntu24_04.pkr.hcl
│       └── http/
│           ├── user-data     # Cloud-init autoinstall config
│           └── meta-data
└── terraform/
    ├── core/                 # VM deployment and cluster config
    │   ├── providers.tf      # bpg/proxmox provider
    │   ├── vms.tf            # VM resources
    │   ├── cluster_config.tf # Pools, roles, users, timezones
    │   ├── envfiles.tf       # Cloud-init snippets
    │   ├── data.tf           # Vault and Proxmox data sources
    │   ├── locals.tf         # Local variable definitions
    │   └── backend.tf        # Wasabi S3 state backend
    ├── dns/                  # PowerDNS zone and record management
    │   ├── main.tf           # Zone definitions and record modules
    │   └── modules/
    │       └── dns_record/   # Reusable A/PTR record module
    ├── netbox/               # Netbox IPAM tracking
    │   ├── cluster.tf        # Proxmox cluster definition
    │   └── vms.tf            # VM and IP address inventory
    ├── auth/                 # Identity and access management
    │   ├── keycloak_realm.tf # Keycloak realm with LDAP federation
    │   ├── keycloak_clients.tf # OIDC client definitions
    │   └── users_groups.tf   # FreeIPA users and groups
    └── external/             # Shared YAML configuration
        ├── lab.yml           # Lab-wide settings and templates
        ├── vms.yml           # VM definitions
        ├── networks.yml      # Network/bridge mappings
        ├── dns.yml           # Extra DNS records
        └── auth.yml          # User and group definitions
```

## Order of Operations

1. Install Proxmox VE 9.x on each node using ZFS for local storage
2. Configure bonded NICs (bond0 for management, bond1 for internal)
3. Join the hosts to a cluster
4. Run the bootstrap Ansible playbook to install prerequisites and do base configuration
5. Configure Unraid NFS/CIFS shares for shared VM storage and ISOs
6. Run Packer to build Ubuntu 24.04 VM templates on each node:
   ```bash
   cd packer/ubuntu24_04
   packer init .
   packer build ubuntu24_04.pkr.hcl
   ```
7. Run Terraform core to deploy VMs:
   ```bash
   cd terraform/core
   terraform init
   terraform plan
   terraform apply
   ```
8. Run Ansible to configure PowerDNS, Netbox, Keycloak, and FreeIPA
9. Run Terraform DNS/Netbox/Auth to manage records, inventory, and identity:
    ```bash
    cd terraform/dns && terraform init && terraform apply
    cd terraform/netbox && terraform init && terraform apply
    cd terraform/auth && terraform init && terraform apply
    ```

## Storage Configuration

| Datastore  | Type    | Capacity | Purpose                     |
|------------|---------|----------|-----------------------------|
| local      | dir     | 1.8 TB   | Local files, ISOs, snippets |
| local-zfs  | zfspool | 1.8 TB   | Local VM disks (fast)       |
| unraid     | CIFS    | 7.3 TB   | Shared VM storage (SMB)     |
| unraidNFS  | NFS     | 7.3 TB   | Shared VM storage, ISOs     |

## Secrets Management

All sensitive values are stored in HashiCorp Vault under the `homelab/` mount:

| Path                    | Contents                          |
|-------------------------|-----------------------------------|
| `homelab/shared`        | Proxmox URL, root password, SSH   |
| `homelab/terraform`     | Terraform service account, SSH keys|
| `homelab/Proxmox`       | Service user passwords             |
| `homelab/software/pdns` | PowerDNS API key                   |
| `homelab/software/netbox`| Netbox API token                  |
| `homelab/software/freeipa`| FreeIPA admin password           |
| `homelab/software/keycloak`| Keycloak admin password         |
| `homelab/software/ldap` | LDAP bind credentials              |
| `homelab/data/packer`   | Packer Proxmox credentials         |

To run Terraform and pull AWS creds from Vault for Wasabi state backend:

```bash
AWS_ACCESS_KEY_ID=$(vault kv get -mount=homelab -field=terraform_access_key wasabi) \
AWS_SECRET_ACCESS_KEY=$(vault kv get -mount=homelab -field=terraform_secret_key wasabi) \
terraform plan
```

## Known Issues

### Proxmox VE 9.x Notes

- Running Proxmox VE 9.1.0 (pve-manager 9.1.6) on kernel 6.17.13-1-pve
- The bpg/proxmox Terraform provider is used exclusively (Telmate provider removed as unmaintained)
- Ceph Squid is available but not currently deployed (using Unraid NFS/CIFS for shared storage)
- SDN.Use privilege has been added to the Terraform role for SDN support in PVE 9
- Nodes use bonded NICs with jumbo frames (MTU 9000) on internal network (vmbr1)

### Cloud-Init Templates

VM templates are built with Packer using Ubuntu 24.04 LTS (Noble Numbat) and include:
- `qemu-guest-agent` pre-installed
- Cloud-init enabled for dynamic provisioning
- SCSI controller: virtio-scsi-single
- Disk format: raw on local-zfs
- Templates deployed to all four nodes (pve, pve2, pve3, pve4)

## Acknowledgements

* Terraform provider for Proxmox by [bpg](https://registry.terraform.io/providers/bpg/proxmox)
* Packer templates based on work by [Julien Brochet](https://github.com/aerialls/madalynn-packer)
* Additional deployment strategy [TotalDebug](https://totaldebug.uk/posts/automating-proxmox-with-terraform-ansible/)
* K3s things from [Fredrickb](https://fredrickb.com/2023/08/05/setting-up-k3s-nodes-in-proxmox-using-terraform/)
