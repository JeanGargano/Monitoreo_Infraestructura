Vagrant.configure("2") do |config|

  # Configuración global del provider
  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end

  # Servidor de Monitoreo
  config.vm.define "servidor" do |servidor|
    servidor.vm.box = "bento/ubuntu-22.04"
    servidor.vm.hostname = "servidor-monitor"
    servidor.vm.network "private_network", ip: "192.168.50.10"
    servidor.vm.network "forwarded_port", guest: 9090, host: 9090  # Prometheus
    servidor.vm.network "forwarded_port", guest: 3000, host: 3000  # Grafana
    servidor.vm.network "forwarded_port", guest: 80, host: 8080    # Flask App
    servidor.vm.network "forwarded_port", guest: 9104, host: 9104  # MySQL Exporter
    
    servidor.vm.provider "virtualbox" do |vb|
      vb.name = "servidor-monitor"
      vb.memory = "2048"
      vb.cpus = 2
    end
    
    # Carpetas compartidas (soluciona problemas de permisos)
    servidor.vm.synced_folder "./webApp", "/vagrant/webApp"
    servidor.vm.synced_folder ".", "/vagrant"
    
    # Configurar hosts para resolución por nombre
    servidor.vm.provision "shell", inline: <<-SHELL
      grep -q "cliente1" /etc/hosts || echo "192.168.50.11 cliente1" >> /etc/hosts
      grep -q "cliente2" /etc/hosts || echo "192.168.50.12 cliente2" >> /etc/hosts
      grep -q "cliente3" /etc/hosts || echo "192.168.50.13 cliente3" >> /etc/hosts
    SHELL
    
    # Copiar archivos desde carpeta compartida (con permisos correctos)
    servidor.vm.provision "shell", inline: <<-SHELL
      echo "Copiando archivos de aplicación..."
      mkdir -p /home/vagrant/webApp
      mkdir -p /var/www
      
      # Copiar webApp
      cp -r /vagrant/webApp/* /home/vagrant/webApp/ 2>/dev/null || true
      
      # Copiar init.sql
      cp /vagrant/init.sql /home/vagrant/init.sql 2>/dev/null || true
      
      # Ajustar permisos
      chown -R vagrant:vagrant /home/vagrant/webApp
      chown vagrant:vagrant /home/vagrant/init.sql 2>/dev/null || true
    SHELL
    
    # Ejecutar scripts de provisión
    servidor.vm.provision "shell", path: "provision-servidor.sh"
    servidor.vm.provision "shell", path: "script.sh"
  end

  # Cliente 1
  config.vm.define "cliente1" do |cliente1|
    cliente1.vm.box = "bento/ubuntu-22.04"
    cliente1.vm.hostname = "cliente1"
    cliente1.vm.network "private_network", ip: "192.168.50.11"
    cliente1.vm.network "forwarded_port", guest: 9100, host: 9101  # Node Exporter
    
    cliente1.vm.provider "virtualbox" do |vb|
      vb.name = "cliente1"
      vb.memory = "1024"
      vb.cpus = 1
    end
    
    cliente1.vm.provision "shell", inline: <<-SHELL
      grep -q "servidor-monitor" /etc/hosts || echo "192.168.50.10 servidor-monitor" >> /etc/hosts
    SHELL
    
    cliente1.vm.provision "shell", path: "provision-cliente.sh"
  end

  # Cliente 2
  config.vm.define "cliente2" do |cliente2|
    cliente2.vm.box = "bento/ubuntu-22.04"
    cliente2.vm.hostname = "cliente2"
    cliente2.vm.network "private_network", ip: "192.168.50.12"
    cliente2.vm.network "forwarded_port", guest: 9100, host: 9102  # Node Exporter
    
    cliente2.vm.provider "virtualbox" do |vb|
      vb.name = "cliente2"
      vb.memory = "1024"
      vb.cpus = 1
    end
    
    cliente2.vm.provision "shell", inline: <<-SHELL
      grep -q "servidor-monitor" /etc/hosts || echo "192.168.50.10 servidor-monitor" >> /etc/hosts
    SHELL
    
    cliente2.vm.provision "shell", path: "provision-cliente.sh"
  end

  # Cliente 3
  config.vm.define "cliente3" do |cliente3|
    cliente3.vm.box = "bento/ubuntu-22.04"
    cliente3.vm.hostname = "cliente3"
    cliente3.vm.network "private_network", ip: "192.168.50.13"
    cliente3.vm.network "forwarded_port", guest: 9100, host: 9103  # Node Exporter
    
    cliente3.vm.provider "virtualbox" do |vb|
      vb.name = "cliente3"
      vb.memory = "1024"
      vb.cpus = 1
    end
    
    cliente3.vm.provision "shell", inline: <<-SHELL
      grep -q "servidor-monitor" /etc/hosts || echo "192.168.50.10 servidor-monitor" >> /etc/hosts
    SHELL
    
    cliente3.vm.provision "shell", path: "provision-cliente.sh"
  end
end