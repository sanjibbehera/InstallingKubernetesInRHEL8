#!/bin/bash
set -e
IFNAME=$1
ADDRESS="$(ip -4 addr show $IFNAME | grep "inet" | head -1 |awk '{print $2}' | cut -d/ -f1)"
sudo bash -c "echo '${ADDRESS} ${HOSTNAME} ${HOSTNAME}.local' >> /etc/hosts"