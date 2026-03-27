#!/usr/bin/env bash
# cleanup.sh - Prepare the template for conversion by cleaning transient state.
set -euo pipefail

echo ">>> Cleaning apt cache..."
apt-get autoremove -y
apt-get clean -y

echo ">>> Cleaning cloud-init state..."
cloud-init clean --logs

echo ">>> Truncating log files..."
find /var/log -type f -name "*.log" -exec truncate -s 0 {} \;
truncate -s 0 /var/log/lastlog || true
truncate -s 0 /var/log/wtmp || true
truncate -s 0 /var/log/btmp || true

echo ">>> Clearing machine-id (will regenerate on first boot)..."
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id 2>/dev/null || true

echo ">>> Removing SSH host keys (will regenerate on first boot)..."
rm -f /etc/ssh/ssh_host_*

echo ">>> Clearing shell history..."
unset HISTFILE
rm -f /root/.bash_history
rm -f /home/*/.bash_history

echo ">>> Removing temporary files..."
rm -rf /tmp/* /var/tmp/*

echo ">>> Cleanup complete. Template is ready for conversion."
