# InstallingKubernetesInRHEL8
Installation of Kubernetes in RHEL 8 using Kubeadm Package Manager.  
The Repo code is example/reference to be used as steps to install Docker and Kubernetes in RHEL 8.  
I have added elaborate steps in the README file. Please follow the same.

    Preview:
    I used VMWare Workstation Player(Virtualization Software Suite via VMWare) to spin up 3 RHEL 8[8.2 (Ootpa)] VM's.
    Within Minimal Install option, booted the VM and below configuration were made to each of the VM.
      1) Login with root user & change to GUI with cmd: <yum groupinstall "Server with GUI">
      2) To make the GUI option as default, use the command:- <systemctl set-default graphical.target>
      3) Creae a new OS user and provide sudo privilege to this new user.
      4) Set the hostname of the VM to be used for Kubernetes via the command. <hostnamectl set-hostname [HOSTNAME]>
      5) Now reboot the VM to use the GNOME GUI.
      6a) Additionally setup a shell script to setup the hosts with the correct IP whose content is given below.
         #!/bin/bash
         set -e
         IFNAME=$1
         ADDRESS="$(ip -4 addr show $IFNAME | grep "inet" | head -1 |awk '{print $2}' | cut -d/ -f1)"
         sudo bash -c "echo '${ADDRESS} ${HOSTNAME} ${HOSTNAME}.local' >> /etc/hosts"
      6b) Execute the shell script after passing the correct Interface name. 
      7) Now again adjust the file "/etc/hosts" with the IP and HOSTNAME which should look like below, For eg.
         192.168.142.131 Node1
         192.168.142.132 Node2
         192.168.142.128 Master
    

Docker Install Steps:
=================

    Create a shell script with the below content, just copy the content and Docker should be installed in each VMs.
    For the same there is a file called installDocker.sh in the repo code. But still the content is below mentioned.
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
    
