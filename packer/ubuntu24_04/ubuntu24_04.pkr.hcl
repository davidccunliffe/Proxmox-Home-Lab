packer {
  required_plugins {
    proxmox = {
      version = "~> 1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "proxmox_node" {
  type    = string
  default = "pve-02"
}

variable "proxmox_template_name" {
  type    = string
  default = "ubuntu-24.04-tmpl"
}

variable "proxmox_vm_id" {
  type    = string
  default = "200"
}

variable "iso_storage_pool" {
  type    = string
  default = "ds1618"
}

variable "ubuntu_iso_file" {
  type    = string
  default = "ubuntu-24.04.2-live-server-amd64.iso"
}

variable "vm_storage_pool" {
  type    = string
  default = "ds1618"
}

variable "ssh_username" {
  type    = string
  default = "lab"
}

locals {
  proxmox_url      = vault("homelab/data/shared", "proxmox_url")
  proxmox_username = vault("homelab/data/packer", "proxmox_username")
  proxmox_password = vault("homelab/data/packer", "proxmox_password")
  ssh_password     = vault("homelab/data/shared", "template_ssh_password")
}

source "proxmox-iso" "pve01_ubuntu_2404" {
  boot_command = [
    "c<wait>",
    "linux /casper/vmlinuz --- autoinstall net.ifnames=0 biosdevname=0 ip=dhcp ipv6.disable=1 ds=\"nocloud-net;seedfrom=http://{{.HTTPIP}}:{{.HTTPPort}}/\"",
    "<enter><wait>",
    "initrd /casper/initrd",
    "<enter><wait>",
    "boot",
    "<enter>"
  ]

  boot_wait  = "10s"
  cloud_init = true

  disks {
    disk_size    = "20G"
    storage_pool = var.vm_storage_pool
    format       = "qcow2"
    type         = "scsi"
  }

  http_directory = "http"
  iso_file       = "${var.iso_storage_pool}:iso/${var.ubuntu_iso_file}"
  memory         = 2048

  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }

  node                     = "pve-01"
  proxmox_url              = local.proxmox_url
  insecure_skip_tls_verify = true
  username                 = local.proxmox_username
  password                 = local.proxmox_password

  ssh_username = var.ssh_username
  ssh_password = local.ssh_password
  ssh_timeout  = "200m"

  scsi_controller = "virtio-scsi-single"
  template_name   = "pve-01-${var.proxmox_template_name}"
  unmount_iso     = true
  vm_id           = "${var.proxmox_vm_id + 1}"
}

source "proxmox-iso" "pve02_ubuntu_2404" {
  boot_command = [
    "c<wait>",
    "linux /casper/vmlinuz --- autoinstall net.ifnames=0 biosdevname=0 ip=dhcp ipv6.disable=1 ds=\"nocloud-net;seedfrom=http://{{.HTTPIP}}:{{.HTTPPort}}/\"",
    "<enter><wait>",
    "initrd /casper/initrd",
    "<enter><wait>",
    "boot",
    "<enter>"
  ]

  boot_wait = "10s"

  disks {
    disk_size    = "20G"
    storage_pool = var.vm_storage_pool
    format       = "qcow2"
    type         = "scsi"
  }

  http_directory = "http"
  iso_file       = "${var.iso_storage_pool}:iso/${var.ubuntu_iso_file}"
  memory         = 2048

  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }

  node                     = "pve-02"
  proxmox_url              = local.proxmox_url
  insecure_skip_tls_verify = true
  username                 = local.proxmox_username
  password                 = local.proxmox_password

  ssh_username = var.ssh_username
  ssh_password = local.ssh_password
  ssh_timeout  = "200m"

  scsi_controller = "virtio-scsi-single"
  template_name   = "pve-02-${var.proxmox_template_name}"
  unmount_iso     = true
  vm_id           = "${var.proxmox_vm_id + 2}"
}

source "proxmox-iso" "pve03_ubuntu_2404" {
  boot_command = [
    "c<wait>",
    "linux /casper/vmlinuz --- autoinstall net.ifnames=0 biosdevname=0 ip=dhcp ipv6.disable=1 ds=\"nocloud-net;seedfrom=http://{{.HTTPIP}}:{{.HTTPPort}}/\"",
    "<enter><wait>",
    "initrd /casper/initrd",
    "<enter><wait>",
    "boot",
    "<enter>"
  ]

  boot_wait = "10s"

  disks {
    disk_size    = "20G"
    storage_pool = var.vm_storage_pool
    format       = "qcow2"
    type         = "scsi"
  }

  http_directory = "http"
  iso_file       = "${var.iso_storage_pool}:iso/${var.ubuntu_iso_file}"
  memory         = 2048

  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }

  node                     = "pve-03"
  proxmox_url              = local.proxmox_url
  insecure_skip_tls_verify = true
  username                 = local.proxmox_username
  password                 = local.proxmox_password

  ssh_username = var.ssh_username
  ssh_password = local.ssh_password
  ssh_timeout  = "200m"

  scsi_controller = "virtio-scsi-single"
  template_name   = "pve-03-${var.proxmox_template_name}"
  unmount_iso     = true
  vm_id           = "${var.proxmox_vm_id + 3}"
}

build {
  sources = [
    "source.proxmox-iso.pve01_ubuntu_2404",
    "source.proxmox-iso.pve02_ubuntu_2404",
    "source.proxmox-iso.pve03_ubuntu_2404"
  ]

  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "sudo cloud-init clean"
    ]
  }
}
