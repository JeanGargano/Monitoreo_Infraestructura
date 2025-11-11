# Sistema de Monitoreo con Prometheus, Grafana y Flask

Este proyecto implementa un entorno de monitoreo completo utilizando **Prometheus**, **Grafana** y una aplicación desarrollada en **Flask**, desplegada sobre **Apache2** mediante **mod_wsgi**.  
El sistema se ejecuta en máquinas virtuales gestionadas por **Vagrant**, donde un servidor central coordina la recolección de métricas desde varios clientes mediante **Node Exporter**.



## 1. Levantamiento del entorno con Vagrant

El primer paso consistió en levantar todo el entorno virtualizado con el comando:

```bash
vagrant up
```
Una vez que la máquina virtual esté en ejecución, accede a ella mediante:

```bash
vagrant ssh
```



## 2. Instalación de Apache2 y mod_wsgi

Luego, instala el servidor Apache2 y el módulo mod_wsgi para Python 3:

```bash
sudo apt install apache2
sudo apt install libapache2-mod-wsgi-py3
sudo systemctl restart apache2
```



## 3. Configuración de la aplicación Flask en el servidor

Dentro de la máquina virtual, dirígete al directorio /home/vagrant y copia la carpeta de la aplicación Flask (webApp) al directorio raíz de Apache:

```bash
cd /home/vagrant
sudo cp -r webApp /var/www
```



## 4. Creación del archivo application.wsgi

A continuación, crea el archivo WSGI dentro de la carpeta del proyecto Flask:

```bash
cd /var/www/webApp
sudo vim application.wsgi

import sys
import logging
logging.basicConfig(stream=sys.stderr)
sys.path.insert(0, "/var/www/")
sys.path.insert(0, "/var/www/webApp/")
from webApp.run import app as application
```

Este archivo le indica a Apache cómo inicializar la aplicación Flask y cuál es el punto de entrada.




## 5. Configuración del sitio en Apache

Edita el archivo de configuración por defecto de Apache para enlazar el WSGI con el servidor:

```bash
sudo vim /etc/apache2/sites-available/000-default.conf

<VirtualHost *:80>
    ServerName tu-dominio.com
    ServerAdmin webmaster@localhost

    DocumentRoot /var/www/webApp

    WSGIDaemonProcess webapp user=www-data group=www-data threads=5
    WSGIScriptAlias / /var/www/webApp/application.wsgi

    <Directory /var/www/webApp>
        WSGIProcessGroup webapp
        WSGIApplicationGroup %{GLOBAL}
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/webapp_error.log
    CustomLog ${APACHE_LOG_DIR}/webapp_access.log combined
</VirtualHost>
```



## 6. Reinicio del servicio Apache

Para aplicar los cambios y cargar la nueva configuración, reinicia el servicio Apache con:

```bash
sudo systemctl restart apache2
```



## 👨‍💻 Autores

Karen Giselle Lopez, Monica Chicangana, Jean Pool Esguerra, Jeam lfred
Última actualización: noviembre de 2025
