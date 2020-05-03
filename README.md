# InstallingKubernetesInRHEL8
Installation of Kubernetes in RHEL 8 using Kubeadm Package Manager.  
Installation of Kubernetes Dashboard for having brief overview of the Kubernetes Cluster.  
The Repo code is example/reference to be used as steps to install Docker and Kubernetes in RHEL 8.  
I have added elaborate steps in the README file. Please follow the same.  
This is a simple K8s cluster Installation & Docker installation in 3 VMs.  
Important Note: The default interface naming convention in RHEL8 start with "ens" instead of "eth" as in RHEL7.

    Preview:
    I have used VMWare Workstation Player(VMWare Virtualization Software Suite) to spin up 3 RHEL 8[8.2 (Ootpa)] VM's.
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
      6b) Execute the shell script after passing the correct Interface name. [Correct Interface name should be passed]
      --> you can find the correct interface name using the command. <ip -4 a show>
      7) Now again adjust the file "/etc/hosts" with the IP and HOSTNAME which should look like below, For eg.
         192.168.142.131 Node1
         192.168.142.132 Node2
         192.168.142.128 Master
    

Docker Install Steps for RHEL 8 VM:
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
        "exec-opts": ["native.cgroupdriver=cgroupfs"],
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
    
K8s Installation on Master RHEL 8 VM.
=====================

    The shell script "installKubeadmMaster.sh" has hte details to install Kubernetes in the master VM  
    which is also known as the Kuebernetes Control Plane.
    As I am working on a dev/test environment, I have disable the firewall to make it easy for me.
    
    But if you are working in production environment, you must enable the below ports in your firewall.
    Details are provided below in tabular format:-
        PROTOCOL        PORT        SOURCE                                          APPLICATION
        TCP             443/6443    Worker Nodes, API Requests, and End-Users       KUBEAPISERVER
        TCP             44134       ----                                            HELM
        TCP             2379-2380   Master Nodes & Worker Nodes                     ETCD
        TCP             10250       Master nodes                                    KUBELET
        TCP             10251       Master Nodes                                    KUBE-SCHEDULER
        TCP             10252       Master Nodes                                    KUBE-CONTROLLER-MANAGER
        TCP             10255       Master Nodes                                    KUBELET READ-ONLY
        TCP             30000-32767 ----                                            NODEPORT SERVICES
        

Script 'installKubeadmMaster.sh' to be installed in Master Node.
=======================
    The snippet of the script "installKubeadmMaster.sh" is as below, please do not make any changes 
    until unless it is necessary to make changes in the scripts or there are any more requirements on top of 
    installing the Kubernetes Cluster installation via kubeadm package manager.
    
    #!/bin/bash
    
    sudo systemctl stop firewalld
    sudo systemctl disable firewalld
    
    sudo modprobe br_netfilter
    sudo bash -c "echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables"
    
    sudo sysctl --system
    
    sudo bash -c "cat >> /etc/yum.repos.d/kubernetes.repo" <<EOF
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
    sudo systemctl enable --now kubelet
    
    sudo bash -c "cat >> /etc/sysctl.d/k8s.conf" <<EOF
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
    EOF
    
    sudo swapoff -a
    sudo sed '$s/^/# /' -i /etc/fstab
    
    sudo bash -c "cat >> /etc/sysctl.conf" <<EOF
    net.ipv4.ip_forward = 1
    EOF
    
    sudo sysctl -p
    
    sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=`sudo cat /etc/hosts | head -3 | tail -1 | cut -d " " -f1`
    sudo sleep 120 && sudo mkdir -p ~/.kube && sudo cp -i /etc/kubernetes/admin.conf ~/.kube/config && sudo chown -R $(id -u):$(id -g) ~/.kube
    kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

Important Note while the Master script is getting executed.
====================================

    When the line <sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=> is being 
    executed, it will print the join syntax for the worker nodes to join the cliuster. For e.g. the below is 
    example for the join syntax, copy this for reference, once the installation is complete, execute it to
    join the Kubernetes cluster.
    
    kubeadm join 192.168.142.128:6443 --token exnkul.n52bs7cop1awo78a \
    --discovery-token-ca-cert-hash sha256:ebc4d4958c95d5563f3dde4353e1b95aa24f49c21811f6151546764aa01a04e5
    
Script 'installKubeadmNodes.sh' to be installed in Worker Node(s).
=======================

    The snippet of the script "installKubeadmNodes.sh" is as below, please do not make any changes 
    until unless it is necessary to make changes in the scripts or there are any more requirements on top of 
    installing the Kubernetes Cluster installation via kubeadm package manager.
    
    #!/bin/bash
    
    sudo systemctl stop firewalld
    sudo systemctl disable firewalld
    
    sudo modprobe br_netfilter
    sudo bash -c "echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables"
    sudo sysctl --system
    
    sudo bash -c "cat >> /etc/yum.repos.d/kubernetes.repo" <<EOF
    [kubernetes]
    name=Kubernetes
    baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
    enabled=1
    gpgcheck=1
    repo_gpgcheck=1
    gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
    EOF
    
    sudo setenforce 0 && sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
    sudo dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
    sudo systemctl enable --now kubelet
    
    sudo bash -c "cat >> /etc/sysctl.d/k8s.conf" <<EOF
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
    EOF
    
    sudo sysctl --system
    sudo swapoff -a
    sudo sed '$s/^/# /' -i /etc/fstab
    
    sudo bash -c "cat >> /etc/sysctl.conf" <<EOF
    net.ipv4.ip_forward = 1
    EOF
    
    sudo sysctl -p
    
Important Note for Worker Nodes.
==================

    Once the above shell script is executed, use the above join command in each worker nodes. For eg.
    sudo kubeadm join 192.168.142.128:6443 --token exnkul.n52bs7cop1awo78a \
    --discovery-token-ca-cert-hash sha256:ebc4d4958c95d5563f3dde4353e1b95aa24f49c21811f6151546764aa01a04e5
    
#### Note to check...

Now once the worker nodes join the kubernetes cluster, make a note to check the messages file  
in '/var/log' folder to check if there are any errors.  
Check the status of the worker nodes via the command 'kubectl get nodes'  
Also check the status of worker pods via the command 'kubeclt get pods --all-namespaces -o wide'  
<The above command is to check all the pods in all namespaces present in the cluster>  
Important Note is that the pods take little time to startup, so make a note of the RESTART column,  
If that is 0 and the pod status is RUNNING, then everything is fine.
    
#### Install Kubernetes Dashboard...

Please follow the below steps to setup dashboard to have a graphical GUI representation of the Cluster.  
Please execute the below command to deploy the dashboard. 
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml  
[CREATE ADMIN USER FOR THE DASHBOARD], use the below YAML FILE to create serviceaccount:-  

    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: admin-user
      namespace: kubernetes-dashboard
        
   
[Create ClusterRoleBinding]  

    There is an already Cluster role 'cluster-admin', hence we need a new Cluster RoleBinding and attach to serviceaccount.
    Use the below YAML File to create the required ClusterRoleBinding.  
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: admin-user
    roleRef:  
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
    name: cluster-admin
    subjects:
    - kind: ServiceAccount
      name: admin-user
      namespace: kubernetes-dashboard  
  
[Bearer Token]  
    
    Now we need to find the token to login to the Dashboard.
    Please use the below command to find the token.
    kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')

#### Output of the above command should look like below.
    
    Name:         admin-user-token-v57nw
    Namespace:    kubernetes-dashboard
    Labels:       <none>
    Annotations:  kubernetes.io/service-account.name: admin-user
              kubernetes.io/service-account.uid: 0303243c-4040-4a58-8a47-849ee9ba79c1

    Type:  kubernetes.io/service-account-token
    
    Data
    ====
    ca.crt:     1066 bytes
    namespace:  20 bytes
    token:  eyJhbGciOiJSUzI1NiIsImtpZCI6IiJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJhZG1pbi11c2VyLXRva2VuLXY1N253Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImFkbWluLXVzZXIiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiIwMzAzMjQzYy00MDQwLTRhNTgtOGE0Ny04NDllZTliYTc5YzEiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6a3ViZXJuZXRlcy1kYXNoYm9hcmQ6YWRtaW4tdXNlciJ9.Z2JrQlitASVwWbc-s6deLRFVk5DWD3P_vjUFXsqVSY10pbjFLG4njoZwh8p3tLxnX_VBsr7_6bwxhWSYChp9hwxznemD5x5HLtjb16kI9Z7yFWLtohzkTwuFbqmQaMoget_nYcQBUC5fDmBHRfFvNKePh_vSSb2h_aYXa8GV5AcfPQpY7r461itme1EXHQJqv-SN-zUnguDguCTjD80pFZ_CmnSE1z9QdMHPB8hoB4V68gtswR1VLa6mSYdgPwCHauuOobojALSaMc3RH7MmFUumAgguhqAkX3Omqd3rJbYOMRuMjhANqd08piDC3aIabINX6gP5-Tuuw2svnV6NYQ
    
    
### Accessing the Kubernetes Dashboard UI..

    At the moment, Dashboard only supports logging in with a Bearer Token. 
    Hence with the above methods, we get the bearer token which can used to login the Dashboard.
    To access the Dashboard using the kubectl command-line tool, trigger the below command.
    kubectl proxy
    
    Now the URL to access the Dashboard please use the below URL.
    http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/


#### Trigger APP Deployment in Cluster.

    Use the below YAML File to trigger NGINX APP Deployement in the Cluster.
    
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: nginx-deployment
    spec:
      selector:
        matchLabels:
          app: nginx
      replicas: 4 # tells deployment to run 4 pods matching the template
      template:
        metadata:
          labels:
            app: nginx
        spec:
          containers:
          - name: nginx
            image: nginx:1.14.2
            ports:
            - containerPort: 80
