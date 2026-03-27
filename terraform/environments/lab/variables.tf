#===============================================================================
# Lab Environment Variables
#===============================================================================

variable "proxmox_endpoint" {
  description = "Proxmox API endpoint URL"
  type        = string
  default     = "https://pve.dcclab.lan:8006/"
}

variable "proxmox_username" {
  description = "Proxmox API username"
  type        = string
  default     = "root@pam"
}

variable "proxmox_password" {
  description = "Proxmox API password"
  type        = string
  sensitive   = true
}

variable "github_username" {
  description = "GitHub username for SSH public key retrieval"
  type        = string
  default     = "davidccunliffe"
}

variable "domain" {
  description = "Internal DNS domain"
  type        = string
  default     = "lab.davidccunliffe.pro"
}

variable "template_vm_id" {
  description = "VM ID of the Ubuntu 24.04 Packer template to clone"
  type        = number
  default     = 201
}

variable "chr_image" {
  description = "Path to MikroTik CHR disk image on Proxmox storage (e.g., unraidNFS:iso/chr-7.18.img)"
  type        = string
  default     = "unraidNFS:iso/chr-7.18.img"
}
