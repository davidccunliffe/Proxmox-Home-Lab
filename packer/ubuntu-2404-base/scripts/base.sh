#!/usr/bin/env bash
# base.sh - Install base packages and apply updates.
set -euo pipefail

echo ">>> Waiting for apt locks to clear..."
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do sleep 2; done

echo ">>> Updating package lists..."
apt-get update -y

echo ">>> Performing dist-upgrade..."
apt-get dist-upgrade -y

echo ">>> Installing common packages..."
apt-get install -y \
  curl \
  wget \
  gnupg \
  ca-certificates \
  apt-transport-https \
  jq \
  python3 \
  python3-pip \
  qemu-guest-agent

echo ">>> Enabling qemu-guest-agent..."
systemctl enable qemu-guest-agent
systemctl start qemu-guest-agent || true

echo ">>> Base provisioning complete."
