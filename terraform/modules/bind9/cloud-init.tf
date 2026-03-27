##############################################################################
# Template rendering
##############################################################################

locals {
  primary_ip   = var.ips[0]
  secondary_ip = var.ips[1]

  # Build reverse-lookup PTR records from the forward A records.
  # For each single-IP record, create a PTR entry.
  # Skip round-robin entries (multiple IPs) if a dedicated record already
  # exists for that IP (e.g. vault-1/2/3 cover the same IPs as vault).
  ptr_records = {
    for name, ips in var.dns_records :
    # Reverse the last two octets for the PTR name within the /16 zone.
    # e.g. 172.16.0.20 -> 0.20  (the zone already covers 16.172)
    join(".", reverse(split(".", ips[0]))) => "${name}.${var.domain}"
    if length(ips) == 1
  }

  named_conf_options = templatefile(
    "${path.module}/templates/named.conf.options.tpl",
    {
      forwarders = var.forwarders
    }
  )

  named_conf_local_primary = templatefile(
    "${path.module}/templates/named.conf.local.primary.tpl",
    {
      domain       = var.domain
      secondary_ip = local.secondary_ip
      reverse_zone = var.reverse_zone_network
    }
  )

  named_conf_local_secondary = templatefile(
    "${path.module}/templates/named.conf.local.secondary.tpl",
    {
      domain       = var.domain
      primary_ip   = local.primary_ip
      reverse_zone = var.reverse_zone_network
    }
  )

  forward_zone_file = templatefile(
    "${path.module}/templates/db.lab.davidccunliffe.pro.tpl",
    {
      domain             = var.domain
      primary_hostname   = var.hostnames[0]
      secondary_hostname = var.hostnames[1]
      serial             = var.zone_serial
      records            = var.dns_records
    }
  )

  reverse_zone_file = templatefile(
    "${path.module}/templates/db.reverse.tpl",
    {
      domain             = var.domain
      primary_hostname   = var.hostnames[0]
      secondary_hostname = var.hostnames[1]
      serial             = var.zone_serial
      ptr_records        = local.ptr_records
    }
  )

  # Cloud-init user-data for each instance (index 0 = primary, 1 = secondary)
  cloud_init_configs = [
    for i in range(length(var.hostnames)) : {
      hostname         = var.hostnames[i]
      ip               = var.ips[i]
      is_primary       = i == 0
      named_conf_local = i == 0 ? local.named_conf_local_primary : local.named_conf_local_secondary
    }
  ]
}

##############################################################################
# Cloud-init user-data
##############################################################################

# Primary (dns-1) cloud-init writes zone files directly since it is the master.
# Secondary (dns-2) receives zones via AXFR, so no zone files are written.

resource "proxmox_virtual_environment_file" "cloud_init" {
  count = length(var.hostnames)

  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.nodes[count.index]

  source_raw {
    data = <<-CIEOF
#cloud-config
hostname: ${local.cloud_init_configs[count.index].hostname}
fqdn: ${local.cloud_init_configs[count.index].hostname}.${var.domain}
manage_etc_hosts: true

users:
  - name: ${var.ci_user}
    groups: [adm, sudo]
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
${join("\n", [for key in var.ci_ssh_keys : "      - ${key}"])}

package_update: true
package_upgrade: true

packages:
  - bind9
  - bind9-utils
  - dnsutils

write_files:
  - path: /etc/bind/named.conf.options
    owner: root:bind
    permissions: "0644"
    content: |
${indent(6, local.named_conf_options)}
  - path: /etc/bind/named.conf.local
    owner: root:bind
    permissions: "0644"
    content: |
${indent(6, local.cloud_init_configs[count.index].named_conf_local)}
%{if local.cloud_init_configs[count.index].is_primary~}
  - path: /etc/bind/db.${var.domain}
    owner: root:bind
    permissions: "0644"
    content: |
${indent(6, local.forward_zone_file)}
  - path: /etc/bind/db.${var.reverse_zone_network}
    owner: root:bind
    permissions: "0644"
    content: |
${indent(6, local.reverse_zone_file)}
%{endif~}

runcmd:
  - systemctl enable named
  - systemctl restart named
    CIEOF

    file_name = "bind9-${local.cloud_init_configs[count.index].hostname}-ci.yml"
  }
}
