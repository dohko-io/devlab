# -*- mode: ruby -*-
# vi: set ft=ruby :

HOST_IP="10.10.3.10"
HOST_NAME="dohko-lab"

def install_plugins (plugins=[], restart=false)
  installed = false

  plugins.each do |plugin|
    unless Vagrant.has_plugin? plugin 
      system ("vagrant plugin install #{plugin}")
      puts "Plugin #{plugin} installed!"
      installed = true
    end
  end

  if installed and restart
    puts "Dependencies installed, restarting vagrant ..."
    exec "vagrant #{ARGV.join(' ')}"
  end
  
  return installed
end

plugins = ["vagrant-docker-compose",
  "vagrant-vbguest",
  "vagrant-proxyconf",
  "vagrant-proxyconf",
  "vagrant-env",
  "vagrant-persistent-storage",
  "vagrant-cachier"]

install_plugins(plugins, restart = true)

def has_been_provisioned?(node_name, provisioner_name = "virtualbox")
  file_name = "#{File.dirname(__FILE__)}/.vagrant/machines/#{node_name}/#{provisioner_name}/action_provision" 
  return File.exist?(file_name)
end

def disable_ipv4_forwarding(node)
  node.vm.provision "shell", inline: <<-SHELL

    function systctl_set() {
      key=$1
      value=$2
      config_path='/etc/sysctl.conf'
      # set now
      sysctl -w ${key}=${value}
      # persist on reboot
      if grep -q "${key}" "${config_path}"; then
        sed -i "s/^${key}.*$/${key} = ${value}/" "${config_path}"
      else
        echo "${key} = ${value}" >> "${config_path}"
      fi
    }

    echo '>>> Enabling IPv4 Forwarding'
    systctl_set net.ipv4.ip_forward 1
  SHELL
end

Vagrant.configure("2") do |config|

  config.vm.define "dohko-lab", primary: true do |dohkolab|
    dohkolab.vm.box      = "trusty-server-cloudimg-amd64"
    dohkolab.vm.hostname = "dohko-lab"
    dohkolab.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box"
    dohkolab.vm.box_download_checksum = "4a39a1bf9736162e917f1eacf209349e9f5913d4190ee56a0826f9f8cf81625f"
    dohkolab.vm.box_download_checksum_type = "sha256"

    dohkolab.ssh.forward_agent = true
    dohkolab.ssh.keys_only = true
    dohkolab.ssh.forward_x11 = true

    if Vagrant.has_plugin?('vagrant-vbguest')

      provisioned = false # has_been_provisioned?("#{HOST_NAME}")

      dohkolab.vbguest.no_remote = provisioned
      dohkolab.vbguest.auto_update = !provisioned
    end

    dohkolab.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--memory", 4096]
      vb.customize ["modifyvm", :id, "--ioapic", "on", "--cpus", 4]
      vb.name = "#{HOST_NAME}"
    end

    # Create a private network, which allows host-only access to the machine
    # using a specific IP.
    dohkolab.vm.network "private_network", ip: "#{HOST_IP}"

    dohkolab.vm.synced_folder ".", "/vagrant", disable: true
    dohkolab.vm.synced_folder ".", "/home/vagrant/devlab", disable: false
    # dohkolab.vm.synced_folder "../", "/home/vagrant/workspace", disable: false

    disable_ipv4_forwarding(dohkolab)

    dohkolab.vm.provision "shell", inline: <<-SHELL
    
      apt-get update  -y
      apt-get install -y build-essential
      apt-get install -y software-properties-common
      apt-get install -y byobu curl git htop man unzip vim wget

      echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
      add-apt-repository -y ppa:webupd8team/java
      apt-get update
      apt-get install -y oracle-java8-installer

      apt-get autoremove -y

      rm -rf /var/lib/apt/lists/*
      rm -rf /var/cache/oracle-jdk8-installer

      wget -qO- http://apache.mediamirrors.org/maven/maven-3/3.5.0/binaries/apache-maven-3.5.0-bin.tar.gz | tar xzvf - -C /opt/
      ln -s /opt/apache-maven-3.5.0 /opt/maven
      chown -R vagrant:vagrant /opt/maven

      { \
        echo '#!/bin/sh'; \
        echo 'set -e'; \
        echo ; \
        echo ; \
        echo 'export MAVEN_HOME=/opt/maven' ; \
        echo 'export PATH=$PATH:$MAVEN_HOME/bin' ; \
        echo ; \
      } >> /etc/maven

      curl https://bootstrap.pypa.io/get-pip.py | sudo -H python
      pip install supervisor
      mkdir -p /etc/supervisor/conf.d/ /var/log/supervisor/ /var/log/dohko/

      wget -O- https://www.rabbitmq.com/rabbitmq-release-signing-key.asc | sudo apt-key add -
      echo 'deb http://www.rabbitmq.com/debian/ testing main' | sudo tee /etc/apt/sources.list.d/rabbitmq.list

      apt-get update -yq
      apt-get install -y rabbitmq-server
      rabbitmqctl start_app

      rabbitmqctl add_user excalibur Par1Zone_eX
      rabbitmqctl set_user_tags excalibur administration
      rabbitmqctl set_permissions -p / excalibur ".*" ".*" ".*"

      cp /home/vagrant/devlab/scripts/.aliases /etc

      DOHKO_HOME="/opt/dohko"

      { \
        echo '#!/bin/sh'; \
        echo 'set -e'; \
        echo ; \
        echo "export DOHKO_HOME=$DOHKO_HOME" ;\
        echo ; \
        echo 'export _JAVA_OPTIONS=-Djava.net.preferIPv4Stack=true' ; \
        echo 'export _JAVA_OPTIONS=\"${_JAVA_OPTIONS} -Dorg.excalibur.provider.name=local\"' ; \
        echo 'export _JAVA_OPTIONS=\"${_JAVA_OPTIONS} -Dorg.excalibur.provider.region.name=local\"' ; \
        echo 'export _JAVA_OPTIONS=\"${_JAVA_OPTIONS} -Dorg.excalibur.provider.region.zone.name=local\"' ; \
        echo 'export _JAVA_OPTIONS=\"${_JAVA_OPTIONS} -Dorg.excalibur.user.name=vagrant\"' ; \
        echo 'export _JAVA_OPTIONS=\"${_JAVA_OPTIONS} -Dorg.excalibur.user.keyname=vagrant\"' ; \
        echo 'export _JAVA_OPTIONS=\"${_JAVA_OPTIONS} -Dorg.excalibur.environment.local=true\"' ;\
        echo ; \
        echo 'export _JAVA_OPTIONS=\"${_JAVA_OPTIONS} -Dorg.excalibur.instance.hostname=#{HOST_NAME}\"' ; \
        echo 'export _JAVA_OPTIONS=\"${_JAVA_OPTIONS} -Dorg.excalibur.application.data.dir=/home/vagrant/.dohko\"' ; \
        echo ; \
        echo 'export _JAVA_OPTIONS=\"${_JAVA_OPTIONS} -Dorg.excalibur.logs.dir=/opt/dohko/logs\"' ; \
        echo ; \
        echo 'export _JAVA_OPTIONS=\"${_JAVA_OPTIONS} -Dorg.excalibur.server.host=#{HOST_IP}\"' ;\
        echo 'export _JAVA_OPTIONS=\"${_JAVA_OPTIONS} -Dorg.excalibur.application.database.dir=/opt/dohko/db\"' ;\
        echo ; \
        echo 'export _JAVA_OPTIONS=\"${_JAVA_OPTIONS} -Dorg.excalibur.database.initialize=true\"' ; \
        echo ; \
        echo 'export _JAVA_OPTIONS=\"${_JAVA_OPTIONS} -Dorg.excalibur.overlay.is.bootstrap=true\"' ; \
        echo 'export _JAVA_OPTIONS=\"${_JAVA_OPTIONS} -Dorg.excalibur.overlay.port=9090\"' ; \

        echo 'export _JAVA_OPTIONS=\"${_JAVA_OPTIONS} -Dorg.excalibur.rabbit.host=#{HOST_IP}\"' ; \
        echo 'export _JAVA_OPTIONS=\"${_JAVA_OPTIONS} -Dorg.excalibur.rabbit.username=excalibur\"' ; \
        echo 'export _JAVA_OPTIONS=\"${_JAVA_OPTIONS} -Dorg.excalibur.rabbit.password=Par1Zone_eX\"' ;\
        echo ; \
        echo 'export _JAVA_OPTIONS=\"${_JAVA_OPTIONS} -Dorg.excalibur.xmpp.certificate.file=$DOHKO_HOME/certificates/excalibur.jks\"' ;\
        echo ; \
      } >> /etc/dohko

      mkdir -p $DOHKO_HOME/db $DOHKO_HOME/logs $DOHKO_HOME/certificates
      cp /home/vagrant/devlab/conf/excalibur.jks $DOHKO_HOME/certificates/
      chown -R vagrant:vagrant $DOHKO_HOME

      cp -R /home/vagrant/devlab/conf/h2 /opt/
      mkdir -p /opt/h2/logs/
      chown -R vagrant:vagrant /opt/h2

      { \
        echo '#!/bin/sh'; \
        echo 'set -e'; \
        echo ; \

        echo 'export H2_HOME=/opt/h2' ; \
        echo ; \
      } >> /etc/h2

      { \
        echo ; \
        echo 'source /etc/maven' ; \
        echo 'source /etc/dohko' ; \
        echo 'source /etc/h2' ; \
        echo 'source /etc/.aliases' ; \
        echo ; \
      } >> /home/vagrant/.bashrc

      cp /home/vagrant/devlab/conf/supervisord.conf /etc/supervisor/conf.d/
      chown -R vagrant:vagrant /etc/supervisor/conf.d/ /var/log/supervisor/ /home/vagrant

    SHELL

    dohkolab.vm.provision "shell", 
       name: "ssearch",
       path: "scripts/ssearch.sh",
       privileged: true

    dohkolab.vm.provision "shell", 
       name: "dohko",
       path: "scripts/dohko.sh",
       privileged: false

    dohkolab.vm.provision "shell",
      name: "supervisord",
      run: "always",
      privileged: false,
      path: "scripts/startup.sh"

    dohkolab.vm.provision :docker
    dohkolab.vm.provision :docker_compose

  end
end
