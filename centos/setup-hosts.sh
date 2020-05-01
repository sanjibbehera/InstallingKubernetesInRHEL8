#!/bin/bash
set -e
IFNAME=$1
ADDRESS="$(ip -4 addr show $IFNAME | grep "inet" | head -1 |awk '{print $2}' | cut -d/ -f1)"
sed -e "s/^.*${HOSTNAME}.*/${ADDRESS} ${HOSTNAME} ${HOSTNAME}.local/" -i /etc/hosts

sudo yum install -y wget net-tools

# Update /etc/hosts about other hosts
sudo cat >> /etc/hosts <<EOF
192.168.13.10  kubernetes-centos8-master
192.168.13.11  workerone-centos8-nodeone
192.168.13.12  workertwo-centos8-nodetwo
EOF