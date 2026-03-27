##############################################################################
# Cloud-init user-data snippets — control plane nodes
##############################################################################

resource "proxmox_virtual_environment_file" "cloud_init_cp" {
  count = var.cp_count

  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.cp_nodes[count.index]

  source_raw {
    data = templatefile("${path.module}/templates/cloud-init-k8s.yaml.tpl", {
      hostname     = var.cp_hostnames[count.index]
      dns_domain   = var.dns_domain
      default_user = var.default_user
      github_user  = var.github_user
      k8s_version  = var.k8s_version
    })
    file_name = "cloud-init-${var.cp_hostnames[count.index]}.yaml"
  }
}

##############################################################################
# Cloud-init user-data snippets — worker nodes
##############################################################################

resource "proxmox_virtual_environment_file" "cloud_init_worker" {
  count = var.worker_count

  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.worker_nodes[count.index]

  source_raw {
    data = templatefile("${path.module}/templates/cloud-init-k8s.yaml.tpl", {
      hostname     = var.worker_hostnames[count.index]
      dns_domain   = var.dns_domain
      default_user = var.default_user
      github_user  = var.github_user
      k8s_version  = var.k8s_version
    })
    file_name = "cloud-init-${var.worker_hostnames[count.index]}.yaml"
  }
}
