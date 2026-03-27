# Proxmox-Home-Lab

Packer, Terraform, and Ansible code to run a three node clustered Proxmox Home Lab running **Proxmox VE 9.x**.

## Architecture

```
                     +-----------+
                     |  Wasabi   |
                     | S3 State  |
                     +-----+-----+
                           |
          +----------------+----------------+
          |                |                |
     +----v----+     +-----v----+     +-----v----+
     | pve-01  |     | pve-02   |     | pve-03   |
     | .0.211  |     | .0.212   |     | .0.213   |
     +---------+     +----------+     +----------+
          |                |                |
          +-------+--------+--------+-------+
                  |  Ceph Cluster   |
                  +-----------------+
                         |
     +----------+--------+---------+----------+
     |          |        |         |          |
   VMs:      K8s     PowerDNS   Netbox   WireGuard
           Cluster   (HA pair)            (DMZ)
```

### Network Layout

| Network  | Bridge | Subnet       | Purpose              |
|----------|--------|--------------|----------------------|
| Internal | vmbr10 | 10.0.0.0/24  | Primary VM network   |
| DMZ      | vmbr40 | 10.40.0.0/24 | Public-facing services |
| Fibre    | vmbr2  | 10.30.1.0/24 | Storage/high-speed   |
| Isolated | vmbr100| 10.100.0.0/24| Isolated testing     |
| Testing  | vmbr101| 10.101.0.0/24| Development/testing  |

### Deployed VMs

| VM Name        | Role              | IP           | Cores | RAM   |
|----------------|-------------------|--------------|-------|-------|
| kubes          | K8s Load Balancer | 10.0.0.64    | 2     | 4 GB  |
| k8s-control-1  | K8s Controller    | 10.0.0.65    | 2     | 4 GB  |
| k8s-worker-1   | K8s Worker        | 10.0.0.66    | 2     | 4 GB  |
| k8s-worker-2   | K8s Worker        | 10.0.0.67    | 2     | 4 GB  |
| keycloak       | Identity Provider | 10.0.0.32    | 2     | 2 GB  |
| vpn            | WireGuard VPN     | 10.40.0.80   | 2     | 4 GB  |
| opa            | OPA Policy Server | 10.0.0.50    | 2     | 4 GB  |
| minecraft      | Minecraft Server  | 10.0.0.30    | 2     | 4 GB  |
| netbox         | Netbox IPAM       | 10.0.0.40    | 2     | 2 GB  |
| pdns-1         | PowerDNS Primary  | 10.0.0.241   | 2     | 2 GB  |
| pdns-2         | PowerDNS Secondary| 10.0.0.242   | 2     | 2 GB  |

## Requirements

### Lab Servers (3x bare metal)

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

Three node Proxmox VE 9.x cluster installed with shared storage (Ceph + NFS). If you already have Proxmox installed and clustered, skip to the step in the [Order of Operations](#order-of-operations) that matches your current state.

### Automation and Responsibilities

**Ansible** handles:
- Cloud image creation
- Ceph installation and configuration
- Proxmox VLAN setup
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
    │   ├── pezlab_int.tf     # pezlab.lan zone
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

1. Install Proxmox VE 9.x on each node, using xfs for storage, leaving the 2TB NVMe drive untouched for Ceph
2. Join the hosts to a cluster
3. Run the bootstrap Ansible playbook to install prerequisites and do base configuration
4. Run the `vlan_setup.yml` playbook to configure networks (vmbr10, vmbr40, vmbr2, vmbr100, vmbr101)
5. Configure Ceph (ceph-vm for VMs, ceph-ct for containers, cephfs for shared filesystem)
6. Configure NFS share for Synology DS1618
7. Run Packer to build Ubuntu 24.04 VM templates on each node:
   ```bash
   cd packer/ubuntu24_04
   packer init .
   packer build ubuntu24_04.pkr.hcl
   ```
8. Run Terraform core to deploy VMs:
   ```bash
   cd terraform/core
   terraform init
   terraform plan
   terraform apply
   ```
9. Run Ansible to configure PowerDNS, Netbox, Keycloak, and FreeIPA
10. Run Terraform DNS/Netbox/Auth to manage records, inventory, and identity:
    ```bash
    cd terraform/dns && terraform init && terraform apply
    cd terraform/netbox && terraform init && terraform apply
    cd terraform/auth && terraform init && terraform apply
    ```

## Storage Configuration

| Datastore | Type | Purpose              |
|-----------|------|----------------------|
| ceph-vm   | Ceph | VM disks (SSD-backed)|
| ceph-ct   | Ceph | Container storage    |
| cephfs    | Ceph | Shared filesystem    |
| ds1618    | NFS  | ISOs, snippets, backups |

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

### PowerDNS

To generate a new salt for PowerDNS admin:

```bash
source flask/bin/activate
export FLASK_APP=./powerdnsadmin/__init__.py
python -c 'import bcrypt; print(bcrypt.gensalt().decode())'
```

### Proxmox VE 9.x Notes

- Proxmox VE 9.x ships with Debian 13 (Trixie) and Linux kernel 6.x
- The bpg/proxmox Terraform provider is used exclusively (Telmate provider removed as unmaintained)
- Ceph Squid is the supported Ceph release for PVE 9.x
- SDN.Use privilege has been added to the Terraform role for SDN support in PVE 9

### Cloud-Init Templates

VM templates are built with Packer using Ubuntu 24.04 LTS (Noble Numbat) and include:
- `qemu-guest-agent` pre-installed
- Cloud-init enabled for dynamic provisioning
- SCSI controller: virtio-scsi-single
- Templates deployed to all three nodes (pve-01, pve-02, pve-03)

## Acknowledgements

* Terraform provider for Proxmox by [bpg](https://registry.terraform.io/providers/bpg/proxmox)
* Packer templates based on work by [Julien Brochet](https://github.com/aerialls/madalynn-packer)
* Ceph Ansible code taken and consolidated from [peacedata0](https://github.com/peacedata0/proxmox-ansible-1)
* Synology Certs Role by [JohnVillalovos](https://github.com/JohnVillalovos/synology_certs)
* Additional deployment strategy [TotalDebug](https://totaldebug.uk/posts/automating-proxmox-with-terraform-ansible/)
* K3s things from [Fredrickb](https://fredrickb.com/2023/08/05/setting-up-k3s-nodes-in-proxmox-using-terraform/)
