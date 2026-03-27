# Proxmox Home Lab

Infrastructure-as-code for a 4-node Proxmox VE 9.1 home lab with MikroTik firewall, HashiCorp Vault PKI, Bind9 DNS, and Kubernetes — fully automated with Terraform, Packer, Ansible, and GitLab CI/CD.

## Architecture

```
        Internet
            |
    ┌───────┴───────┐
    │  Home Router  │   192.168.189.0/22
    │  (upstream)   │   DHCP to MikroTik WAN
    └───────┬───────┘
            │ vmbr0 (WAN)
    ┌───────┴───────┐
    │  MikroTik CHR │   VRRP pair (mikrotik-1 + mikrotik-2)
    │  Firewall/NAT │   Virtual IP: 172.16.0.1
    │  K8s API LB   │   NAT, Firewall, DNS forwarding
    └───────┬───────┘
            │ vmbr2 (LAN: 172.16.0.0/16)
            │
    ┌───────┼──────────────────────────────────────┐
    │       │                                      │
    │  ┌────┴─────┐  ┌──────────┐  ┌───────────┐  │
    │  │ Vault HA │  │ Bind9 HA │  │    K8s     │  │
    │  │ (3-node) │  │ (2-node) │  │  Cluster   │  │
    │  │ PKI + CA │  │   DNS    │  │ 3 CP + 3W  │  │
    │  │ .0.10-12 │  │ .0.20-21 │  │ Calico CNI │  │
    │  └──────────┘  └──────────┘  └───────────┘  │
    │                                              │
    │  Proxmox Cluster: pve, pve2, pve3, pve4      │
    └──────────────────────────────────────────────┘
```

### Network Design

| Segment    | Bridge | Subnet             | Purpose                        |
|------------|--------|--------------------|--------------------------------|
| Management | vmbr0  | 192.168.189.0/22   | Proxmox mgmt, MikroTik WAN    |
| Cluster    | vmbr1  | 10.0.0.0/22        | Proxmox corosync (do not touch)|
| VM Network | vmbr2  | 172.16.0.0/16      | All VMs, behind MikroTik FW    |
| K8s Pods   | —      | 10.244.0.0/16      | Calico overlay (VXLAN)         |
| K8s Svcs   | —      | 10.96.0.0/12       | Kubernetes service CIDRs       |

### Subnet Allocation

| Subnet          | Usage                          |
|-----------------|--------------------------------|
| 172.16.0.0/24   | Infrastructure (FW, Vault, DNS)|
| 172.16.1.0/24   | Kubernetes nodes               |
| 172.16.10.0/24  | General purpose VMs (future)   |

### VM Inventory

| VM              | Node  | IP            | Cores | RAM   | Disk  | Role                    |
|-----------------|-------|---------------|-------|-------|-------|-------------------------|
| mikrotik-1      | pve   | DHCP / .0.2   | 1     | 512M  | 1G    | Firewall/GW (VRRP master)|
| mikrotik-2      | pve2  | DHCP / .0.3   | 1     | 512M  | 1G    | Firewall/GW (VRRP backup)|
| vault-1         | pve   | 172.16.0.10   | 2     | 4G    | 20G   | Vault + PKI CA (Raft)   |
| vault-2         | pve2  | 172.16.0.11   | 2     | 4G    | 20G   | Vault + PKI CA (Raft)   |
| vault-3         | pve3  | 172.16.0.12   | 2     | 4G    | 20G   | Vault + PKI CA (Raft)   |
| dns-1           | pve3  | 172.16.0.20   | 1     | 2G    | 10G   | Bind9 primary           |
| dns-2           | pve4  | 172.16.0.21   | 1     | 2G    | 10G   | Bind9 secondary         |
| k8s-cp-1        | pve   | 172.16.1.10   | 4     | 8G    | 40G   | K8s control plane       |
| k8s-cp-2        | pve2  | 172.16.1.11   | 4     | 8G    | 40G   | K8s control plane       |
| k8s-cp-3        | pve3  | 172.16.1.12   | 4     | 8G    | 40G   | K8s control plane       |
| k8s-worker-1    | pve2  | 172.16.1.20   | 4     | 16G   | 80G   | K8s worker              |
| k8s-worker-2    | pve3  | 172.16.1.21   | 4     | 16G   | 80G   | K8s worker              |
| k8s-worker-3    | pve4  | 172.16.1.22   | 4     | 16G   | 80G   | K8s worker              |

**Total: 13 VMs | 37 cores | 92.5 GB RAM** (across 4 nodes × 96GB = 384GB available)

## Requirements

### Lab Servers (4× bare metal)

Proxmox VE is a **bare-metal hypervisor** — it installs directly onto your servers from the [Proxmox VE 9.x ISO](https://www.proxmox.com/en/downloads). Each node in this lab has:
- Intel Core i9 (12 cores / 20 threads)
- 96 GB RAM
- ZFS local storage + Unraid NFS/CIFS shared storage

### Workstation / GitLab Runner

The automation runs from a **GitLab Runner** (shell + Docker-in-Docker) on `gitlab.davidccunliffe.com`. The runner needs:

- [Packer](https://www.packer.io/) >= 1.11
- [Terraform](https://www.terraform.io/) >= 1.5
- [Ansible](https://www.ansible.com/) >= 2.15
- `jq`, `curl`, SSH client

### Terraform Providers

| Provider    | Version  | Purpose               |
|-------------|----------|-----------------------|
| bpg/proxmox | ~> 0.78 | Proxmox VE management |
| hashicorp/http | ~> 3.4 | GitHub SSH key fetch |

### External Services

| Service     | URL                          | Purpose              |
|-------------|------------------------------|----------------------|
| GitLab      | gitlab.davidccunliffe.com    | CI/CD + TF state     |
| Cloudflare  | davidccunliffe.pro zone      | External DNS (split-horizon) |

## Project Structure

```
.
├── .gitlab-ci.yml                    # 3-stage CI/CD pipeline
├── packer/
│   └── ubuntu-2404-base/             # Ubuntu 24.04 LTS base template
│       ├── ubuntu-2404-base.pkr.hcl  # Packer template (4 nodes)
│       ├── http/                     # Cloud-init autoinstall
│       │   ├── user-data
│       │   └── meta-data
│       └── scripts/                  # Provisioning scripts
│           ├── base.sh               # Packages, updates, SSH keys
│           ├── hardening.sh          # Security hardening
│           └── cleanup.sh            # Cloud-init clean
├── terraform/
│   ├── environments/
│   │   └── lab/                      # Lab environment composition
│   │       ├── main.tf               # Module wiring
│   │       ├── providers.tf          # bpg/proxmox + GitLab backend
│   │       ├── variables.tf          # Environment inputs
│   │       └── outputs.tf            # Infrastructure outputs
│   └── modules/
│       ├── mikrotik/                 # MikroTik CHR VRRP pair
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   ├── outputs.tf
│       │   ├── versions.tf
│       │   └── files/
│       │       └── mikrotik-config.rsc.tpl
│       ├── vault/                    # 3-node Vault HA (Raft)
│       │   ├── main.tf
│       │   ├── cloud-init.tf
│       │   ├── variables.tf
│       │   ├── outputs.tf
│       │   ├── versions.tf
│       │   └── templates/
│       │       └── vault.hcl.tpl
│       ├── bind9/                    # Bind9 HA DNS pair
│       │   ├── main.tf
│       │   ├── cloud-init.tf
│       │   ├── variables.tf
│       │   ├── outputs.tf
│       │   ├── versions.tf
│       │   └── templates/
│       │       ├── named.conf.options.tpl
│       │       ├── named.conf.local.primary.tpl
│       │       ├── named.conf.local.secondary.tpl
│       │       ├── db.lab.davidccunliffe.pro.tpl
│       │       └── db.reverse.tpl
│       └── kubernetes/              # K8s cluster (3 CP + 3 workers)
│           ├── main.tf
│           ├── cloud-init.tf
│           ├── variables.tf
│           ├── outputs.tf
│           ├── versions.tf
│           └── templates/
│               └── cloud-init-k8s.yaml.tpl
└── ansible/
    ├── ansible.cfg
    ├── inventory/
    │   └── hosts.yml                 # All infrastructure hosts
    ├── group_vars/
    │   └── all.yml                   # Global variables
    └── playbooks/
        ├── 00-proxmox-bridge.yml     # Create vmbr2 on all nodes
        ├── 01-vault-init.yml         # Initialize Vault + PKI CA
        ├── 02-k8s-bootstrap.yml      # kubeadm init + Calico + join
        └── 03-distribute-ca.yml      # Push Root CA to all hosts
```

## Deployment Guide

### Prerequisites

1. **Proxmox VE 9.x** installed on all 4 nodes and joined to a cluster
2. **Storage** configured: `local`, `local-zfs`, `unraidNFS` available on all nodes
3. **GitLab** running at `gitlab.davidccunliffe.com` with a registered runner
4. **MikroTik CHR image** downloaded and uploaded to `unraidNFS:iso/chr-7.18.img`

### Step 0: Create vmbr2 Bridge

Every Proxmox node needs the `vmbr2` bridge for the internal VM network. Run the Ansible playbook or create manually:

```bash
# Option A: Ansible (recommended)
cd ansible
ansible-playbook playbooks/00-proxmox-bridge.yml

# Option B: Manual (on each node via SSH)
cat >> /etc/network/interfaces << 'EOF'

auto vmbr2
iface vmbr2 inet manual
        bridge-stp off
        bridge-fd 0
EOF
ifreload -a
```

### Step 1: Build VM Template

Build the hardened Ubuntu 24.04 template on all nodes:

```bash
cd packer/ubuntu-2404-base
packer init .
packer build ubuntu-2404-base.pkr.hcl
```

This creates a template (ID 201-204) on each node with:
- Latest security patches
- SSH keys from github.com/davidccunliffe
- Disabled root login and password auth
- qemu-guest-agent, unattended-upgrades
- Hardened sysctl settings

### Step 2: Deploy Infrastructure (Terraform)

```bash
cd terraform/environments/lab
terraform init
terraform plan
terraform apply
```

This deploys all 13 VMs in dependency order:
1. MikroTik CHR VRRP pair (gateway comes up first)
2. Vault HA cluster
3. Bind9 DNS servers
4. Kubernetes nodes

### Step 3: Initialize Vault + PKI CA

```bash
cd ansible
ansible-playbook playbooks/01-vault-init.yml
```

This:
- Initializes Vault with 5 key shares (3 threshold)
- Unseals all 3 nodes
- Creates Root CA and Intermediate CA
- Enables ACME endpoint for automated certificate issuance
- Saves `vault-keys.json` and `root-ca.pem` locally

**IMPORTANT:** `vault-keys.json` contains the master unseal keys and root token. Store it securely and remove from the runner.

### Step 4: Distribute CA Certificate

```bash
ansible-playbook playbooks/03-distribute-ca.yml
```

Installs the Root CA certificate on all VMs so they trust certs issued by Vault.

### Step 5: Bootstrap Kubernetes

```bash
ansible-playbook playbooks/02-k8s-bootstrap.yml
```

This:
- Runs `kubeadm init` on k8s-cp-1
- Installs Calico CNI (VXLAN cross-subnet mode)
- Joins remaining control plane and worker nodes
- Saves `kubeconfig` locally

```bash
export KUBECONFIG=ansible/kubeconfig
kubectl get nodes -o wide
```

### GitLab CI/CD Pipeline

All steps above are automated in `.gitlab-ci.yml` as a 3-stage pipeline:

| Stage       | Job               | Trigger  | Action                        |
|-------------|-------------------|----------|-------------------------------|
| validate    | packer:validate   | auto     | Validate Packer templates     |
| validate    | terraform:validate| auto     | Validate + fmt check          |
| validate    | ansible:lint      | auto     | Syntax check playbooks        |
| infra       | terraform:plan    | auto     | Plan infrastructure changes   |
| infra       | terraform:apply   | manual   | Apply Terraform               |
| configure   | vault:init        | manual   | Initialize Vault + PKI        |
| configure   | distribute:ca     | manual   | Push CA certs to all hosts    |
| platform    | k8s:bootstrap     | manual   | Bootstrap Kubernetes cluster  |

**Required CI/CD Variables** (Settings → CI/CD → Variables):

| Variable          | Type   | Description                        |
|-------------------|--------|------------------------------------|
| `PROXMOX_PASSWORD`| masked | Proxmox `root@pam` password        |
| `PROXMOX_ENDPOINT`| var    | `https://pve.dcclab.lan:8006/`     |
| `ANSIBLE_SSH_KEY` | file   | SSH private key for VM access      |

Terraform state is stored in GitLab's built-in HTTP backend (no external S3 needed).

## DNS: Split-Horizon Configuration

### How Split-Horizon DNS Works

Split-horizon DNS serves different DNS responses depending on where the query originates. Internal clients resolve `lab.davidccunliffe.pro` to private IPs (172.16.x.x) via Bind9, while external clients resolve via Cloudflare to public IPs (or get NXDOMAIN if no public record exists).

```
                    ┌──────────────────────────────────┐
                    │       lab.davidccunliffe.pro      │
                    └──────────┬───────────────────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
     ┌────────▼─────┐  ┌──────▼──────┐  ┌──────▼──────┐
     │  Internal    │  │  VPN Client │  │  External   │
     │  (172.16.x)  │  │  (remote)   │  │  (public)   │
     └──────┬───────┘  └──────┬──────┘  └──────┬──────┘
            │                 │                │
     ┌──────▼───────┐  ┌─────▼───────┐  ┌─────▼───────┐
     │   Bind9      │  │  Bind9 via  │  │  Cloudflare │
     │ 172.16.0.20  │  │  WireGuard  │  │     DNS     │
     │   .0.21      │  │   tunnel    │  │             │
     └──────────────┘  └─────────────┘  └─────────────┘
```

### Internal DNS (Bind9 — already configured)

Bind9 is deployed automatically and serves the `lab.davidccunliffe.pro` zone internally. All VMs use Bind9 as their DNS resolver (172.16.0.20, 172.16.0.21). MikroTik forwards DNS queries to Bind9.

### External DNS (Cloudflare — manual setup)

To allow external resolution of `lab.davidccunliffe.pro`, configure Cloudflare:

1. **Log into Cloudflare** → select `davidccunliffe.pro` zone

2. **Create an NS delegation** for the `lab` subdomain:
   ```
   lab.davidccunliffe.pro.  NS  ns1.lab.davidccunliffe.pro.
   lab.davidccunliffe.pro.  NS  ns2.lab.davidccunliffe.pro.
   ```

3. **Create glue records** pointing to your public IP (or WireGuard endpoint):
   ```
   ns1.lab.davidccunliffe.pro.  A  <YOUR_PUBLIC_IP>
   ns2.lab.davidccunliffe.pro.  A  <YOUR_PUBLIC_IP>
   ```

4. **Port forward** on your home router:
   - Forward TCP/UDP port 53 from `<YOUR_PUBLIC_IP>` → `172.16.0.20` (dns-1)
   - Or use a non-standard port and configure Cloudflare accordingly

5. **Alternative (no port forward):** If you don't want to expose DNS publicly, external users can use a VPN (WireGuard) to reach the internal Bind9 servers. In this case, skip the Cloudflare NS delegation and just configure VPN clients to use 172.16.0.20/21 as DNS.

### Resolving on Your Home Firewall

If your home router/firewall manages DNS for the entire network (e.g., pfSense, OPNsense, UniFi, or another MikroTik):

1. **Add a conditional forwarder** on your main firewall/router:
   - Domain: `lab.davidccunliffe.pro`
   - Forward to: `172.16.0.20`, `172.16.0.21`

2. For **pfSense/OPNsense** (Unbound):
   ```
   # /var/unbound/unbound.conf or via GUI → Services → DNS Resolver → Overrides
   forward-zone:
       name: "lab.davidccunliffe.pro"
       forward-addr: 172.16.0.20
       forward-addr: 172.16.0.21
   ```

3. For **MikroTik RouterOS** (if your main router is also MikroTik):
   ```routeros
   /ip dns static add name=lab.davidccunliffe.pro type=FWD forward-to=172.16.0.20
   /ip dns static add name=lab.davidccunliffe.pro type=FWD forward-to=172.16.0.21
   ```

4. For **UniFi/dnsmasq**:
   ```
   server=/lab.davidccunliffe.pro/172.16.0.20
   server=/lab.davidccunliffe.pro/172.16.0.21
   ```

This ensures any device on your home network can resolve `*.lab.davidccunliffe.pro` without changing each device's DNS settings.

## Understanding FreeIPA and Keycloak

> **Note:** FreeIPA and Keycloak are planned for a future phase and are not deployed by this automation yet.

### FreeIPA

[FreeIPA](https://www.freeipa.org/) is an integrated identity management solution that combines:

- **LDAP Directory** (389 Directory Server) — centralized user/group database
- **Kerberos KDC** — single sign-on authentication for Linux hosts
- **DNS** — integrated DNS management (optional, we use Bind9 separately)
- **Certificate Authority** (Dogtag) — host and service certificates
- **HBAC/SUDO rules** — centralized access control policies

**In this lab**, FreeIPA would replace per-host user management. Instead of creating users on each VM individually, you define them once in FreeIPA and all hosts authenticate against it. SSH keys, sudo rules, and password policies are managed centrally.

**Example use case:** You SSH to `k8s-cp-1` and authenticate with your FreeIPA credentials. Your SSH key, group memberships, and sudo permissions are pulled from LDAP automatically.

### Keycloak

[Keycloak](https://www.keycloak.org/) is an identity and access management (IAM) platform for **web applications and APIs**:

- **SSO (Single Sign-On)** — log in once, access all web apps
- **OIDC/OAuth2/SAML** — standard protocols for application authentication
- **Identity Brokering** — federate with external identity providers (Google, GitHub, FreeIPA LDAP)
- **User Federation** — connect to FreeIPA's LDAP so web app users = Linux users
- **Fine-grained Authorization** — roles, groups, and permissions per application

**In this lab**, Keycloak would sit in front of web UIs (Netbox, Grafana, ArgoCD, etc.) and provide SSO backed by FreeIPA's user directory. Users log into Keycloak once and get access to all lab services.

**How they work together:**
```
User → Keycloak (web SSO) → LDAP federation → FreeIPA (user store)
User → SSH to host → PAM/SSSD → Kerberos/LDAP → FreeIPA (user store)
```

Both use FreeIPA as the single source of truth for user identities.

## Private CA (Vault PKI)

The lab runs its own Certificate Authority using Vault's PKI secrets engine:

```
Root CA (vault pki/)
  └── Intermediate CA (vault pki_int/)
        └── Server certificates (auto-issued via ACME or CLI)
```

### Issuing Certificates

**Via ACME (automated):**
```bash
certbot certonly \
  --server http://vault.lab.davidccunliffe.pro:8200/v1/pki_int/acme/directory \
  -d myservice.lab.davidccunliffe.pro \
  --standalone
```

**Via Vault CLI (manual):**
```bash
vault write pki_int/issue/lab-davidccunliffe-pro \
  common_name="myservice.lab.davidccunliffe.pro" \
  ttl="720h"
```

All hosts trust the Root CA certificate (distributed by `03-distribute-ca.yml`), so TLS connections between services "just work."

## Future Template Variants

The Packer base template (`ubuntu-2404-base`) is designed as a foundation. Planned variants:

| Template           | Based On        | Additions                              |
|--------------------|-----------------|----------------------------------------|
| `ubuntu-2404-base` | Ubuntu 24.04    | Current: hardened, updated, SSH keys   |
| `ubuntu-2404-cis1` | base            | CIS Level 1 benchmark compliance       |
| `ubuntu-2404-cis2` | base            | CIS Level 2 benchmark compliance       |
| `ubuntu-2404-docker`| base           | Docker CE + containerd pre-installed   |
| `alma-9-base`      | AlmaLinux 9     | Hardened, SELinux enforcing             |
| `windows-2025`     | Windows Server  | WinRM, OpenSSH, hardened               |

## Hardware Summary

| Node | CPU                     | RAM   | Storage                     |
|------|-------------------------|-------|-----------------------------|
| pve  | Intel i9 (12C/20T)      | 96 GB | local-zfs (1.8TB), Unraid   |
| pve2 | Intel i9 (12C/20T)      | 96 GB | local-zfs (1.8TB), Unraid   |
| pve3 | Intel i9 (12C/20T)      | 96 GB | local-zfs (1.8TB), Unraid   |
| pve4 | Intel i9 (12C/20T)      | 96 GB | local-zfs (1.8TB), Unraid   |

| Storage    | Type    | Capacity | Shared | Purpose                     |
|------------|---------|----------|--------|-----------------------------|
| local      | dir     | 1.8 TB   | No     | ISOs, snippets              |
| local-zfs  | zfspool | 1.8 TB   | No     | VM disks (fast, per-node)   |
| unraid     | CIFS    | 7.3 TB   | Yes    | Backups, media              |
| unraidNFS  | NFS     | 7.3 TB   | Yes    | ISOs, templates, shared VMs |
