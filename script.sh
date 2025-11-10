#!/bin/bash

# Install MySQL
echo "Installing MySQL"

debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'

sudo apt update
sudo apt install mysql-server -y
sudo systemctl start mysql.service

# Create and fill Database
echo "Creating and filling database"
sudo mysql -h localhost -u root -proot < /home/vagrant/init.sql

# Create MySQL user for Prometheus Exporter
echo "Creating MySQL exporter user"
sudo mysql -h localhost -u root -proot << 'EOF'
CREATE USER IF NOT EXISTS 'exporter'@'localhost' IDENTIFIED BY 'exporter_password' WITH MAX_USER_CONNECTIONS 3;
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'localhost';
FLUSH PRIVILEGES;
EOF

# Adding permissions to remote access
echo "Adding permissions to remote access"
sudo sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql.service

# Install Python Flask and dependencies
echo "Installing Python dependencies"
sudo apt install python3-dev default-libmysqlclient-dev build-essential pkg-config mysql-client python3-pip -y
pip3 install Flask==2.3.3
pip3 install flask-cors
pip3 install Flask-MySQLdb
pip3 install Flask-SQLAlchemy
pip3 install prometheus-client 

# Create systemd service for Flask app
echo "Creating Flask service"
cat > /etc/systemd/system/webapp.service << 'EOF'
[Unit]
Description=Flask Web Application
After=network.target mysql.service

[Service]
Type=simple
User=vagrant
WorkingDirectory=/home/vagrant/webApp
Environment="FLASK_APP=run.py"
Environment="PATH=/usr/local/bin:/usr/bin:/bin"
ExecStart=/usr/local/bin/flask run --host=0.0.0.0 --port=5000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start webapp service
systemctl daemon-reload
systemctl enable webapp.service
systemctl start webapp.service

# Start MySQL Exporter (ya instalado en provision-servidor.sh)
systemctl daemon-reload
systemctl enable mysqld_exporter
systemctl start mysqld_exporter

echo "=========================================="
echo "Aplicación Web y servicios iniciados!"
echo "=========================================="