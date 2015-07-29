# -*- mode: ruby -*-
# vi: set ft=ruby :

# Make sure we have the hostmanager plugin
unless Vagrant.has_plugin?("vagrant-hostmanager")
  rails 'vagrant-hostmanager plugin is required'
end

Vagrant.configure(2) do |config|
  deployment_type = ENV['OPENSHIFT_DEPLOYMENT_TYPE'] || 'enterprise'
  num_nodes = (ENV['OPENSHIFT_NUM_NODES'] || 2).to_i

  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.include_offline = true
  config.ssh.insert_key = false
  config.vm.provider "virtualbox" do |vbox, override|
    override.vm.box = "ose-3.0.0-base"
    vbox.memory = 1024
    vbox.cpus = 2
    vbox.customize ["modifyvm", :id, "--ioapic", "on"]
  end

  config.vm.define "ose3-dns.example.com" do |helper|
    helper.vm.hostname = "ose3-dns.example.com"
    helper.hostmanager.aliases = %W(ose3-dns.example.com)
    helper.vm.network :private_network, ip: "192.168.100.150"
    helper.vm.provision "fix-hostmanager-bug", type: "shell", run: "always" do |s|
      s.inline = <<-EOT
        sudo restorecon /etc/hosts
        sudo chown root:root /etc/hosts
        EOT
    end
    helper.vm.provision "shell", path: "ose3-dns/install_script.sh"
  end

  num_nodes.times do |n|
    node_index = n+1
    config.vm.define "ose3-node#{node_index}.example.com" do |node|
      node.vm.hostname = "ose3-node#{node_index}.example.com"
      node.hostmanager.aliases = %W(ose3-node#{node_index}.example.com)
      node.vm.network :private_network, ip: "192.168.100.#{200 + n}"
      node.vm.provision "fix-hostmanager-bug", type: "shell", run: "always" do |s|
        s.inline = <<-EOT
          sudo restorecon /etc/hosts
          sudo chown root:root /etc/hosts
          EOT
      end
      node.vm.provision "shell", path: "ose3-node#{node_index}/install_script.sh"
    end
  end

  config.vm.define "ose3-master.example.com" do |master|
    master.vm.hostname = "ose3-master.example.com"
    master.hostmanager.aliases = %W(ose3-master.example.com)
    master.vm.network :private_network, ip: "192.168.100.100"
    master.vm.network :forwarded_port, guest: 8443, host: 8443
    master.vm.provision "shell", path: "ose3-master/install_script.sh"
    master.vm.provision "fix-hostmanager-bug", type: "shell", run: "always" do |s|
      s.inline = <<-EOT
        sudo restorecon /etc/hosts
        sudo chown root:root /etc/hosts
        EOT
    end
    master.vm.provision "ansible" do |ansible|
      ansible.limit = 'all'
      ansible.sudo = true
      ansible.groups = {
        "masters" => ["ose3-master.example.com"],
        "nodes"   => ["ose3-node1.example.com", "ose3-node2.example.com"],
      }
      ansible.extra_vars = {
        openshift_deployment_type: "enterprise",
      }
      ansible.playbook = "projects/openshift-ansible/playbooks/byo/config.yml"
    end
    master.vm.provision "shell", path: "ose3-master/post_install.sh"
  end

end
