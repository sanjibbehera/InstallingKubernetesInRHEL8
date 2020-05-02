#!/bin/bash

sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf list docker-ce
sudo dnf install docker-ce --nobest -y
  
sudo systemctl start docker
sudo systemctl enable docker
  
sudo bash -c "cat >> /etc/docker/daemon.json" <<EOF
{
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "json-file",
    "log-opts": {
    "max-size": "100m"
  },
    "storage-driver": "overlay2",
    "storage-opts": [
       "overlay2.override_kernel_check=true"
    ]
}
EOF
  
sudo systemctl daemon-reload
sudo systemctl restart docker