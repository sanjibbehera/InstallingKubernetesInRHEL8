#!/bin/bash

sudo systemctl disable firewalld

sudo cat >> /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

sudo setenforce 0 && sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
sudo dnf install -y kubelet kubeadm kubectl kubernetes-cni --disableexcludes=kubernetes
sudo systemctl enable --now kubelet && lsmod | grep br_netfilter

sudo cat >> /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sudo sysctl --system
sudo swapoff -a

sudo cat >> /etc/sysctl.conf <<EOF
net.ipv4.ip_forward = 1
EOF

sudo sysctl -p
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=<MASTER HOST IP>
sudo sleep 120 && sudo mkdir -p ~/.kube && sudo cp -i /etc/kubernetes/admin.conf ~/.kube/config && sudo chown -R $(id -u):$(id -g) ~/.kube
sudo kubectl apply -f https://docs.projectcalico.org/v3.11/manifests/calico.yaml