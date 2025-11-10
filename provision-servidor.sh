#!/bin/bash

echo "=========================================="
echo "Instalando Prometheus + Grafana + MySQL"
echo "=========================================="

# Actualizar sistema
apt-get update
apt-get upgrade -y

# Instalar dependencias
apt-get install -y wget curl tar

# ============================================
# INSTALACIÓN DE PROMETHEUS
# ============================================
echo "Instalando Prometheus..."

# Crear usuario para Prometheus
useradd --no-create-home --shell /bin/false prometheus

# Crear directorios
mkdir -p /etc/prometheus
mkdir -p /var/lib/prometheus

# Descargar Prometheus
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v2.47.0/prometheus-2.47.0.linux-amd64.tar.gz
tar -xvf prometheus-2.47.0.linux-amd64.tar.gz
cd prometheus-2.47.0.linux-amd64

# Copiar binarios
cp prometheus /usr/local/bin/
cp promtool /usr/local/bin/

# Copiar archivos de configuración
cp -r consoles /etc/prometheus
cp -r console_libraries /etc/prometheus

# Establecer permisos
chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus /usr/local/bin/promtool
chown -R prometheus:prometheus /etc/prometheus
chown -R prometheus:prometheus /var/lib/prometheus

# Crear archivo de configuración de Prometheus
cat > /etc/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: []

rule_files:
  - "rules.yml"

scrape_configs:
  # Prometheus mismo
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Node Exporter - Infraestructura
  - job_name: 'node_exporter'
    static_configs:
      - targets: 
        - '192.168.50.11:9100'  # cliente1
        - '192.168.50.12:9100'  # cliente2
        - '192.168.50.13:9100'  # cliente3
        labels:
          group: 'clientes'

  # Aplicación Web Flask (a través de Apache)
  - job_name: 'webapp'
    static_configs:
      - targets: ['192.168.50.10:80']
        labels:
          app: 'flask_webapp'
          environment: 'production'
    metrics_path: '/metrics'

  # MySQL Exporter
  - job_name: 'mysql'
    static_configs:
      - targets: ['localhost:9104']
        labels:
          service: 'mysql'
EOF

chown prometheus:prometheus /etc/prometheus/prometheus.yml

# ============================================
# CONFIGURAR ALERTAS
# ============================================
echo "Configurando reglas de alertas..."

cat > /etc/prometheus/rules.yml << 'EOF'
groups:
  - name: infrastructure_alerts
    interval: 30s
    rules:
      - alert: InstanceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Instancia {{ $labels.instance }} caída"
          description: "La instancia {{ $labels.instance }} del job {{ $labels.job }} ha estado caída por más de 1 minuto."
      
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Alto uso de CPU en {{ $labels.instance }}"
          description: "El uso de CPU en {{ $labels.instance }} está por encima del 80% durante más de 2 minutos."
      
      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 85
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Alto uso de memoria en {{ $labels.instance }}"
          description: "El uso de memoria en {{ $labels.instance }} está por encima del 85%."
      
      - alert: DiskSpaceLow
        expr: (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"} * 100) < 20
        for: 1m
        labels:
          severity: warning
        annotations:
          summary: "Poco espacio en disco en {{ $labels.instance }}"
          description: "El espacio disponible en disco en {{ $labels.instance }} está por debajo del 20%."

  - name: application_alerts
    interval: 30s
    rules:
      - alert: WebAppDown
        expr: up{job="webapp"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Aplicación Web caída"
          description: "La aplicación Flask no responde desde hace más de 1 minuto."
      
      - alert: MySQLDown
        expr: up{job="mysql"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "MySQL caído"
          description: "El servidor MySQL no responde desde hace más de 1 minuto."
      
      - alert: HighDatabaseConnections
        expr: mysql_global_status_threads_connected > 100
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Alto número de conexiones MySQL"
          description: "MySQL tiene {{ $value }} conexiones activas."
      
      - alert: HighHTTPErrorRate
        expr: rate(flask_http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Alta tasa de errores HTTP 5xx"
          description: "La aplicación Flask está generando errores 5xx a una tasa de {{ $value }} por segundo."
EOF

chown prometheus:prometheus /etc/prometheus/rules.yml

# Crear servicio systemd para Prometheus
cat > /etc/systemd/system/prometheus.service << 'EOF'
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

# Iniciar Prometheus
systemctl daemon-reload
systemctl start prometheus
systemctl enable prometheus

# ============================================
# INSTALACIÓN DE GRAFANA (MÉTODO OPTIMIZADO)
# ============================================
echo "Instalando Grafana (descarga directa)..."

# Instalar dependencias mínimas
apt-get install -y adduser libfontconfig1

# Descargar Grafana directamente (versión más ligera)
cd /tmp
echo "Descargando Grafana 10.4.2 (~90MB, más rápido que 12.x)..."
wget --progress=bar:force https://dl.grafana.com/oss/release/grafana_10.4.2_amd64.deb

# Instalar paquete .deb
echo "Instalando Grafana..."
dpkg -i grafana_10.4.2_amd64.deb

# Corregir dependencias si hay problemas
apt-get install -f -y

# Iniciar Grafana
systemctl daemon-reload
systemctl enable grafana-server
systemctl start grafana-server

# ============================================
# INSTALACIÓN DE MYSQL EXPORTER
# ============================================
echo "Instalando MySQL Exporter..."

# Crear usuario para MySQL Exporter
useradd --no-create-home --shell /bin/false mysqld_exporter

# Descargar MySQL Exporter
cd /tmp
wget https://github.com/prometheus/mysqld_exporter/releases/download/v0.15.0/mysqld_exporter-0.15.0.linux-amd64.tar.gz
tar -xvf mysqld_exporter-0.15.0.linux-amd64.tar.gz
cp mysqld_exporter-0.15.0.linux-amd64/mysqld_exporter /usr/local/bin/
chown mysqld_exporter:mysqld_exporter /usr/local/bin/mysqld_exporter

# Crear archivo de configuración para MySQL Exporter
cat > /etc/.mysqld_exporter.cnf << 'EOF'
[client]
user=exporter
password=exporter_password
EOF

chown mysqld_exporter:mysqld_exporter /etc/.mysqld_exporter.cnf
chmod 600 /etc/.mysqld_exporter.cnf

# Crear servicio systemd para MySQL Exporter
cat > /etc/systemd/system/mysqld_exporter.service << 'EOF'
[Unit]
Description=MySQL Exporter
Wants=network-online.target
After=network-online.target mysql.service

[Service]
User=mysqld_exporter
Group=mysqld_exporter
Type=simple
ExecStart=/usr/local/bin/mysqld_exporter \
    --config.my-cnf=/etc/.mysqld_exporter.cnf \
    --collect.global_status \
    --collect.info_schema.innodb_metrics \
    --collect.auto_increment.columns \
    --collect.info_schema.processlist \
    --collect.binlog_size \
    --collect.info_schema.tables \
    --collect.info_schema.tablestats \
    --collect.global_variables \
    --collect.perf_schema.tableiowaits \
    --collect.perf_schema.indexiowaits

[Install]
WantedBy=multi-user.target
EOF

# ============================================
# INSTALAR NODE EXPORTER (para el servidor)
# ============================================
echo "Instalando Node Exporter en el servidor..."

# Crear usuario
useradd --no-create-home --shell /bin/false node_exporter

# Descargar Node Exporter
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
tar -xvf node_exporter-1.6.1.linux-amd64.tar.gz
cp node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/
chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Crear servicio
cat > /etc/systemd/system/node_exporter.service << 'EOF'
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

# Agregar node_exporter del servidor a Prometheus
cat >> /etc/prometheus/prometheus.yml << 'EOF'

  # Node Exporter del servidor
  - job_name: 'node_exporter_servidor'
    static_configs:
      - targets: ['localhost:9100']
        labels:
          group: 'servidor'
          role: 'app_database'
EOF

systemctl restart prometheus

# ============================================
# CONFIGURAR DATASOURCE EN GRAFANA
# ============================================
echo "Esperando a que Grafana inicie..."
sleep 20

echo "Configurando datasource de Prometheus en Grafana..."
curl -X POST -H "Content-Type: application/json" -d '{
  "name": "Prometheus",
  "type": "prometheus",
  "access": "proxy",
  "url": "http://localhost:9090",
  "isDefault": true
}' http://admin:admin@localhost:3000/api/datasources

# ============================================
# VERIFICACIÓN FINAL
# ============================================
echo ""
echo "=========================================="
echo " Verificando servicios..."
echo "=========================================="

# Verificar servicios
systemctl is-active --quiet prometheus && echo "✓ Prometheus: ACTIVO" || echo "✗ Prometheus: INACTIVO"
systemctl is-active --quiet grafana-server && echo "✓ Grafana: ACTIVO" || echo "✗ Grafana: INACTIVO"
systemctl is-active --quiet mysqld_exporter && echo "✓ MySQL Exporter: ACTIVO" || echo "✗ MySQL Exporter: INACTIVO"
systemctl is-active --quiet node_exporter && echo "✓ Node Exporter: ACTIVO" || echo "✗ Node Exporter: INACTIVO"

echo ""
echo "=========================================="
echo " Instalación completada!"
echo "=========================================="
echo ""
echo " URLs de acceso:"
echo "   Prometheus:     http://192.168.50.10:9090"
echo "   Grafana:        http://192.168.50.10:3000"
echo "   Flask App:      http://192.168.50.10/productos"
echo "   Métricas Flask: http://192.168.50.10/metrics"
echo "   MySQL Metrics:  http://192.168.50.10:9104/metrics"
echo "   Node Exporter:  http://192.168.50.10:9100/metrics"
echo ""
echo " Credenciales de Grafana:"
echo "   Usuario: admin"
echo "   Contraseña: admin"
echo ""
echo " Dashboards recomendados para importar:"
echo "   - Node Exporter Full: ID 1860"
echo "   - MySQL Overview: ID 7362"
echo ""
echo "=========================================="