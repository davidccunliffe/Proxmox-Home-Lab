#cloud-config
# Kubernetes node preparation - ${hostname}
# kubeadm init/join and Calico install handled by Ansible

hostname: ${hostname}
fqdn: ${hostname}.${dns_domain}
manage_etc_hosts: true

users:
  - name: ${default_user}
    groups: sudo
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_import_id:
      - gh:${github_user}

package_update: true
package_upgrade: true

packages:
  - qemu-guest-agent
  - apt-transport-https
  - ca-certificates
  - curl
  - gnupg
  - lsb-release
  - software-properties-common
  - nfs-common
  - open-iscsi

write_files:
  # Kernel modules for containerd / Kubernetes
  - path: /etc/modules-load.d/k8s.conf
    content: |
      overlay
      br_netfilter

  # Sysctl parameters for Kubernetes networking
  - path: /etc/sysctl.d/99-k8s.conf
    content: |
      net.bridge.bridge-nf-call-iptables  = 1
      net.bridge.bridge-nf-call-ip6tables = 1
      net.ipv4.ip_forward                 = 1

  # containerd default config with systemd cgroup driver
  - path: /etc/containerd/config.toml
    content: |
      version = 2
      [plugins."io.containerd.grpc.v1.cri"]
        sandbox_image = "registry.k8s.io/pause:3.10"
        [plugins."io.containerd.grpc.v1.cri".containerd]
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
            [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
              runtime_type = "io.containerd.runc.v2"
              [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
                SystemdCgroup = true

  # Crictl configuration
  - path: /etc/crictl.yaml
    content: |
      runtime-endpoint: unix:///run/containerd/containerd.sock
      image-endpoint: unix:///run/containerd/containerd.sock
      timeout: 10

runcmd:
  # ---------- Disable swap permanently ----------
  - swapoff -a
  - sed -i '/\sswap\s/d' /etc/fstab
  - systemctl mask swap.target

  # ---------- Load kernel modules ----------
  - modprobe overlay
  - modprobe br_netfilter
  - sysctl --system

  # ---------- Install containerd from Docker APT repo ----------
  - install -m 0755 -d /etc/apt/keyrings
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  - chmod a+r /etc/apt/keyrings/docker.asc
  - |
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
    https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    > /etc/apt/sources.list.d/docker.list
  - apt-get update
  - apt-get install -y containerd.io
  - systemctl daemon-reload
  - systemctl enable --now containerd

  # ---------- Install kubeadm, kubelet, kubectl ----------
  - curl -fsSL https://pkgs.k8s.io/core:/stable:/v${k8s_version}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  - chmod a+r /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  - |
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
    https://pkgs.k8s.io/core:/stable:/v${k8s_version}/deb/ /" \
    > /etc/apt/sources.list.d/kubernetes.list
  - apt-get update
  - apt-get install -y kubelet kubeadm kubectl
  - apt-mark hold kubelet kubeadm kubectl
  - systemctl enable kubelet

  # ---------- Enable QEMU guest agent ----------
  - systemctl enable --now qemu-guest-agent

  # ---------- Signal cloud-init complete ----------
  - echo "Cloud-init k8s prep complete for ${hostname}" > /var/log/cloud-init-k8s-done

power_state:
  mode: reboot
  message: Rebooting after Kubernetes node preparation
  timeout: 30
  condition: true
