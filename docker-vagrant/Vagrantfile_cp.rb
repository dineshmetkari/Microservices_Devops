Vagrant.configure("2") do |config|
  #config.vm.box = "ubuntu/trusty64"
  config.vm.box = "tknerr/ubuntu1604-desktop"
  #config.vm.box = "xenji/ubuntu-17.04-server"
  config.vm.box_version = "2.0.27.1"
  config.vm.synced_folder "../microservice-demo", "/microservice-demo", create: true
  config.vm.synced_folder "../../microservice", "/microservice"
  config.vm.network "forwarded_port", guest: 8090, host: 8090
  
  config.vm.network "forwarded_port", guest: 8080, host: 8080
  config.vm.network "forwarded_port", guest: 8081, host: 8081
  config.vm.network "forwarded_port", guest: 8082, host: 8082
    config.vm.network "forwarded_port", guest: 8083, host: 8083
	
  config.vm.network "forwarded_port", guest: 8761, host: 8761
  config.vm.network "forwarded_port", guest: 8989, host: 8989
  config.vm.provider "virtualbox" do |v|
    v.memory = 3000
    v.cpus = 2
  end
  
  config.vm.provision "docker" do |d|
    #d.build_image "--tag=java /vagrant/java"
    d.build_image "--tag=eureka /vagrant/eureka"
    d.build_image "--tag=customer-app /vagrant/customer-app"
    d.build_image "--tag=catalog-app /vagrant/catalog-app"
    d.build_image "--tag=order-app /vagrant/order-app"
    d.build_image "--tag=turbine /vagrant/turbine"
    d.build_image "--tag=zuul /vagrant/zuul"
  end    
  config.vm.provision "docker", run: "always" do |d|
    d.run "eureka",
      args: "-p 8761:8761 -v /microservice-demo:/microservice-demo"
    d.run "customer-app",
      args: "-v /microservice-demo:/microservice-demo --link eureka:eureka"
    d.run "catalog-app",
      args: "-v /microservice-demo:/microservice-demo --link eureka:eureka"
    d.run "order-app",
      args: "-v /microservice-demo:/microservice-demo --link eureka:eureka"
    d.run "zuul",
      args: "-p 8080:8080 -v /microservice-demo:/microservice-demo --link eureka:eureka"
    d.run "turbine",
      args: "-p 8989:8989 -v /microservice-demo:/microservice-demo --link eureka:eureka"
  end

  
  #########  CHEF
    # refresh apt before installing any packages (as base box might be out of date)
  config.vm.provision "shell", inline: <<-SHELL
     sudo apt-get update
  SHELL
  
  # enable chef
  config.vm.provision "chef_solo" do |chef|
	chef.add_recipe "apache"
	chef.cookbooks_path = "devops/vagrant-linux-chef/provision/cookbooks"
  end
  
   # enable Puppet
  config.vm.provision "puppet" do |puppet|
    puppet.manifests_path = "devops/vagrant-linux-puppet/provision/manifests"
    puppet.module_path = "devops/vagrant-linux-puppet/provision/modules"
    puppet.manifest_file = "default.pp"
  end
  
  
  
end
