#!/usr/bin/env bash
# hardening.sh - Basic security hardening for the Ubuntu 24.04 template.
set -euo pipefail

echo ">>> Waiting for apt locks to clear..."
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do sleep 2; done

# ---------------------------------------------------------------------------
# SSH hardening
# ---------------------------------------------------------------------------
echo ">>> Hardening SSH configuration..."

sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

# Ensure the settings also exist in sshd_config.d drop-ins don't override.
cat > /etc/ssh/sshd_config.d/99-hardening.conf <<'SSHEOF'
PermitRootLogin no
PasswordAuthentication no
SSHEOF

# ---------------------------------------------------------------------------
# UFW - install but do NOT enable (Ansible will handle enablement)
# ---------------------------------------------------------------------------
echo ">>> Installing UFW (will not be enabled)..."
apt-get install -y ufw
# Ensure ufw is not active -- just installed and ready.
ufw --force disable || true

# ---------------------------------------------------------------------------
# Unattended upgrades
# ---------------------------------------------------------------------------
echo ">>> Installing and configuring unattended-upgrades..."
apt-get install -y unattended-upgrades

cat > /etc/apt/apt.conf.d/20auto-upgrades <<'APTEOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
APTEOF

# Enable security updates in unattended-upgrades (usually default, but be explicit).
cat > /etc/apt/apt.conf.d/50unattended-upgrades <<'UUEOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
UUEOF

# ---------------------------------------------------------------------------
# Sysctl hardening
# ---------------------------------------------------------------------------
echo ">>> Applying sysctl hardening..."
cat > /etc/sysctl.d/99-hardening.conf <<'SYSEOF'
# Enable reverse path filtering (anti-spoofing).
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Enable TCP SYN cookies (SYN flood protection).
net.ipv4.tcp_syncookies = 1

# Ignore ICMP broadcast requests.
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Ignore bogus ICMP error responses.
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Do not accept ICMP redirects (prevent MITM attacks).
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Do not send ICMP redirects.
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Do not accept IP source route packets.
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Log martian packets.
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
SYSEOF

sysctl --system

# ---------------------------------------------------------------------------
# Disable core dumps
# ---------------------------------------------------------------------------
echo ">>> Disabling core dumps..."
cat > /etc/security/limits.d/99-disable-core-dumps.conf <<'LIMEOF'
*     hard   core    0
*     soft   core    0
LIMEOF

# Also prevent core dumps via sysctl.
echo "fs.suid_dumpable = 0" >> /etc/sysctl.d/99-hardening.conf
sysctl -p /etc/sysctl.d/99-hardening.conf

# Prevent core dumps via systemd.
mkdir -p /etc/systemd/coredump.conf.d
cat > /etc/systemd/coredump.conf.d/disable.conf <<'CDEOF'
[Coredump]
Storage=none
ProcessSizeMax=0
CDEOF

echo ">>> Hardening complete."
