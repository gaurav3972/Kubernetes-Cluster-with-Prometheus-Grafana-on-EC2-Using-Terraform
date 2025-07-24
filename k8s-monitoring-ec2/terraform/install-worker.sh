#!/bin/bash
set -e
apt update -y && apt install -y docker.io
systemctl enable docker && systemctl start docker

apt install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
apt update && apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
swapoff -a && sed -i '/ swap / s/^/#/' /etc/fstab
