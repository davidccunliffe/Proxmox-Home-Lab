# ---------------------------------------------------------------------------
# Vault Server Configuration - ${node_id}
# ---------------------------------------------------------------------------
# TLS is intentionally disabled for initial bootstrap. The post-deploy
# Ansible playbook will:
#   1. Initialize Vault and unseal the Raft cluster
#   2. Enable the PKI secrets engine as the Private CA
#   3. Configure ACME support on the PKI engine
#   4. Generate TLS certificates for each Vault node
#   5. Re-enable TLS on the listener and update retry_join to https://
# ---------------------------------------------------------------------------

ui = true
disable_mlock = true

storage "raft" {
  path    = "/opt/vault/data"
  node_id = "${node_id}"

  %{ for peer in peers ~}
  retry_join {
    leader_api_addr = "https://${peer.ip}:8200"
  }
  %{ endfor ~}
}

listener "tcp" {
  address         = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_disable     = true
}

api_addr     = "http://${api_addr}:8200"
cluster_addr = "http://${api_addr}:8201"
