packer {
  required_plugins {
    proxmox = {
      version = "~> 1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "proxmox_url" {
  type        = string
  default     = vault("homelab/data/shared", "proxmox_url")
  description = "Proxmox API URL."
}

variable "proxmox_username" {
  type        = string
  default     = vault("homelab/data/packer", "proxmox_username")
  description = "Proxmox API username."
}

variable "proxmox_password" {
  type        = string
  default     = vault("homelab/data/packer", "proxmox_password")
  sensitive   = true
  description = "Proxmox API password."
}

variable "ssh_password" {
  type        = string
  default     = vault("homelab/data/shared", "template_ssh_password")
  sensitive   = true
  description = "SSH password used during the build (via autoinstall)."
}

variable "ssh_username" {
  type    = string
  default = "lab"
}

variable "iso_file" {
  type    = string
  default = "unraidNFS:iso/ubuntu-24.04.2-live-server-amd64.iso"
}

variable "iso_storage_pool" {
  type    = string
  default = "unraidNFS"
}

variable "disk_storage_pool" {
  type    = string
  default = "local-zfs"
}

variable "disk_format" {
  type    = string
  default = "raw"
}

variable "disk_size" {
  type    = string
  default = "20G"
}

variable "memory" {
  type    = number
  default = 2048
}

variable "cores" {
  type    = number
  default = 2
}

variable "network_bridge" {
  type    = string
  default = "vmbr0"
}

variable "github_user" {
  type        = string
  default     = "davidccunliffe"
  description = "GitHub username whose SSH public keys will be installed."
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  template_description = "Ubuntu 24.04 LTS base template - built by Packer on ${timestamp()}"

  boot_command = [
    "c<wait>",
    "linux /casper/vmlinuz --- autoinstall net.ifnames=0 biosdevname=0 ip=dhcp ipv6.disable=1 ds=\"nocloud-net;seedfrom=http://{{.HTTPIP}}:{{.HTTPPort}}/\"",
    "<enter><wait>",
    "initrd /casper/initrd",
    "<enter><wait>",
    "boot",
    "<enter>",
  ]
}

# -----------------------------------------------------------------------------
# Source: pve (node 1) - VM ID 200
# -----------------------------------------------------------------------------

source "proxmox-iso" "ubuntu-2404-pve" {
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  password                 = var.proxmox_password
  insecure_skip_tls_verify = true

  node                 = "pve"
  vm_id                = 200
  vm_name              = "ubuntu-2404-base"
  template_description = local.template_description

  iso_file         = var.iso_file
  iso_storage_pool = var.iso_storage_pool
  unmount_iso      = true

  os       = "l26"
  memory   = var.memory
  cores    = var.cores
  cpu_type = "host"
  machine  = "q35"

  scsi_controller = "virtio-scsi-single"

  disks {
    storage_pool = var.disk_storage_pool
    type         = "scsi"
    disk_size    = var.disk_size
    format       = var.disk_format
    io_thread    = true
  }

  network_adapters {
    model  = "virtio"
    bridge = var.network_bridge
  }

  cloud_init              = true
  cloud_init_storage_pool = var.disk_storage_pool

  boot_command = local.boot_command
  boot_wait    = "10s"

  http_directory = "http"

  ssh_username = var.ssh_username
  ssh_password = var.ssh_password
  ssh_timeout  = "30m"
}

# -----------------------------------------------------------------------------
# Source: pve2 (node 2) - VM ID 201
# -----------------------------------------------------------------------------

source "proxmox-iso" "ubuntu-2404-pve2" {
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  password                 = var.proxmox_password
  insecure_skip_tls_verify = true

  node                 = "pve2"
  vm_id                = 201
  vm_name              = "ubuntu-2404-base"
  template_description = local.template_description

  iso_file         = var.iso_file
  iso_storage_pool = var.iso_storage_pool
  unmount_iso      = true

  os       = "l26"
  memory   = var.memory
  cores    = var.cores
  cpu_type = "host"
  machine  = "q35"

  scsi_controller = "virtio-scsi-single"

  disks {
    storage_pool = var.disk_storage_pool
    type         = "scsi"
    disk_size    = var.disk_size
    format       = var.disk_format
    io_thread    = true
  }

  network_adapters {
    model  = "virtio"
    bridge = var.network_bridge
  }

  cloud_init              = true
  cloud_init_storage_pool = var.disk_storage_pool

  boot_command = local.boot_command
  boot_wait    = "10s"

  http_directory = "http"

  ssh_username = var.ssh_username
  ssh_password = var.ssh_password
  ssh_timeout  = "30m"
}

# -----------------------------------------------------------------------------
# Source: pve3 (node 3) - VM ID 202
# -----------------------------------------------------------------------------

source "proxmox-iso" "ubuntu-2404-pve3" {
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  password                 = var.proxmox_password
  insecure_skip_tls_verify = true

  node                 = "pve3"
  vm_id                = 202
  vm_name              = "ubuntu-2404-base"
  template_description = local.template_description

  iso_file         = var.iso_file
  iso_storage_pool = var.iso_storage_pool
  unmount_iso      = true

  os       = "l26"
  memory   = var.memory
  cores    = var.cores
  cpu_type = "host"
  machine  = "q35"

  scsi_controller = "virtio-scsi-single"

  disks {
    storage_pool = var.disk_storage_pool
    type         = "scsi"
    disk_size    = var.disk_size
    format       = var.disk_format
    io_thread    = true
  }

  network_adapters {
    model  = "virtio"
    bridge = var.network_bridge
  }

  cloud_init              = true
  cloud_init_storage_pool = var.disk_storage_pool

  boot_command = local.boot_command
  boot_wait    = "10s"

  http_directory = "http"

  ssh_username = var.ssh_username
  ssh_password = var.ssh_password
  ssh_timeout  = "30m"
}

# -----------------------------------------------------------------------------
# Source: pve4 (node 4) - VM ID 203
# -----------------------------------------------------------------------------

source "proxmox-iso" "ubuntu-2404-pve4" {
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  password                 = var.proxmox_password
  insecure_skip_tls_verify = true

  node                 = "pve4"
  vm_id                = 203
  vm_name              = "ubuntu-2404-base"
  template_description = local.template_description

  iso_file         = var.iso_file
  iso_storage_pool = var.iso_storage_pool
  unmount_iso      = true

  os       = "l26"
  memory   = var.memory
  cores    = var.cores
  cpu_type = "host"
  machine  = "q35"

  scsi_controller = "virtio-scsi-single"

  disks {
    storage_pool = var.disk_storage_pool
    type         = "scsi"
    disk_size    = var.disk_size
    format       = var.disk_format
    io_thread    = true
  }

  network_adapters {
    model  = "virtio"
    bridge = var.network_bridge
  }

  cloud_init              = true
  cloud_init_storage_pool = var.disk_storage_pool

  boot_command = local.boot_command
  boot_wait    = "10s"

  http_directory = "http"

  ssh_username = var.ssh_username
  ssh_password = var.ssh_password
  ssh_timeout  = "30m"
}

# -----------------------------------------------------------------------------
# Build
# -----------------------------------------------------------------------------

build {
  sources = [
    "source.proxmox-iso.ubuntu-2404-pve",
    "source.proxmox-iso.ubuntu-2404-pve2",
    "source.proxmox-iso.ubuntu-2404-pve3",
    "source.proxmox-iso.ubuntu-2404-pve4",
  ]

  # Wait for cloud-init to finish before running provisioners.
  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 5; done",
    ]
  }

  # Install SSH keys from GitHub.
  provisioner "shell" {
    inline = [
      "echo '>>> Installing SSH public keys from GitHub for ${var.github_user}'",
      "mkdir -p ~/.ssh && chmod 700 ~/.ssh",
      "curl -fsSL https://github.com/${var.github_user}.keys -o ~/.ssh/authorized_keys",
      "chmod 600 ~/.ssh/authorized_keys",
    ]
  }

  # Base packages and updates.
  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | sudo -S -E bash '{{.Path}}'"
    scripts = [
      "scripts/base.sh",
    ]
  }

  # Security hardening.
  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | sudo -S -E bash '{{.Path}}'"
    scripts = [
      "scripts/hardening.sh",
    ]
  }

  # Cleanup.
  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | sudo -S -E bash '{{.Path}}'"
    scripts = [
      "scripts/cleanup.sh",
    ]
  }
}
