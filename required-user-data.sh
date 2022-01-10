#!/bin/bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
overlay
EOF

cat <<EOF | sudo tee /etc/sysctl.d/00-k8s-network.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward                 = 1
EOF

sleep 5
sync

systemctl restart procps
sysctl --system

apt-get update
apt-get install -y apt-transport-https ca-certificates curl

curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl containerd
apt-mark hold kubelet kubeadm kubectl

# Enabling cgroupv2, /etc/default/grub is not respected for some reason, maybe a bug, maybe a feature 
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="/&systemd.unified_cgroup_hierarchy=1 /' /etc/default/grub

# Waiting for the file to write properly? Didn't work without this
sleep 5
sync

# Updating grub so it picks up cgroupv2
update-grub

# Configuring containerd to use cgroupv2
mkdir -p /etc/containerd
containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/g' | sudo tee /etc/containerd/config.toml

reboot &