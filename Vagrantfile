IP_NW = "192.168.13."
KUBERNETES_MASTER_IP = 10
KUBERNETES_WORKERONE_NODE_IP = 11
KUBERNETES_WORKERTWO_NODE_IP = 12

Vagrant.configure("2") do |config|
    config.vm.box = "centos/8"
	config.vm.box_version = "1905.1"
	config.ssh.forward_agent = true
    config.vm.define "kubernetes-centos8-master" do |node|
        node.vm.provider "virtualbox" do |vb|
            vb.name = "kubernetes-centos8-master"
            vb.memory = 2500
            vb.cpus = 2
        end
        node.vm.hostname = "kubernetes-centos8-master"
        node.vm.network :private_network, ip: IP_NW + "#{KUBERNETES_MASTER_IP}"
        node.vm.network "forwarded_port", guest: 22, host: 2210

        node.vm.provision "setup-hosts", :type => "shell", :path => "centos/setup-hosts.sh" do |s|
            s.args = ["eth1"]
        end
        node.vm.provision "setup-dns", type: "shell", :path => "centos/update-dns.sh"
		node.vm.provision "installDocker", type: "shell", :path => "centos/install-docker.sh"
		node.vm.provision "installKubeadmMaster", type: "shell", :path => "centos/installKubeadmMaster.sh"
    end
    config.vm.define "workerone-centos8-nodeone" do |node|
        node.vm.provider "virtualbox" do |vb|
            vb.name = "workerone-centos8-nodeone"
            vb.memory = 3072
            vb.cpus = 2
        end
        node.vm.hostname = "workerone-centos8-nodeone"
        node.vm.network :private_network, ip: IP_NW + "#{KUBERNETES_WORKERONE_NODE_IP}"
        node.vm.network "forwarded_port", guest: 22, host: 3777

        node.vm.provision "setup-hosts", :type => "shell", :path => "centos/setup-hosts.sh" do |s|
            s.args = ["eth1"]
        end
        node.vm.provision "setup-dns", type: "shell", :path => "centos/update-dns.sh"
		node.vm.provision "installDocker", type: "shell", :path => "centos/install-docker.sh"
		node.vm.provision "installKubeadmNodes", type: "shell", :path => "centos/installKubeadmNodes.sh"
    end
    config.vm.define "workertwo-centos8-nodetwo" do |node|
        node.vm.provider "virtualbox" do |vb|
            vb.name = "workertwo-centos8-nodetwo"
            vb.memory = 3072
            vb.cpus = 2
        end
        node.vm.hostname = "workertwo-centos8-nodetwo"
        node.vm.network :private_network, ip: IP_NW + "#{KUBERNETES_WORKERTWO_NODE_IP}"
        node.vm.network "forwarded_port", guest: 22, host: 3666

        node.vm.provision "setup-hosts", :type => "shell", :path => "centos/setup-hosts.sh" do |s|
            s.args = ["eth1"]
        end
        node.vm.provision "setup-dns", type: "shell", :path => "centos/update-dns.sh"
		node.vm.provision "installDocker", type: "shell", :path => "centos/install-docker.sh"
		node.vm.provision "installKubeadmNodes", type: "shell", :path => "centos/installKubeadmNodes.sh"
    end
end