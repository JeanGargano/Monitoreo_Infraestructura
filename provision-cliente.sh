#!/bin/bash

echo "=========================================="
echo "Instalando Node Exporter"
echo "=========================================="

# Actualizar sistema
apt-get update
apt-get upgrade -y

# Instalar dependencias
apt-get install -y wget curl

# Crear usuario para Node Exporter
useradd --no-create-home --shell /bin/false node_exporter

# Descargar Node Exporter
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
tar -xvf node_exporter-1.6.1.linux-amd64.tar.gz

# Copiar binario
cp node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/
chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Crear servicio systemd
cat > /etc/systemd/system/node_exporter.service << 'EOF'
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Iniciar Node Exporter
systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter

# Instalar herramientas adicionales para monitoreo
apt-get install -y stress-ng htop

echo "=========================================="
echo " Node Exporter instalado!"
echo "=========================================="
echo "Métricas disponibles en: http://$(hostname -I | awk '{print $2}'):9100/metrics"
echo ""
echo "   Para generar carga de prueba usa:"
echo "   stress-ng --cpu 2 --timeout 60s    (Prueba CPU)"
echo "   stress-ng --vm 1 --vm-bytes 512M --timeout 60s  (Prueba RAM)"
echo "=========================================="
