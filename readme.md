# Monitoreo_Infraestructura

Este proyecto implementa el despliegue de una aplicación desarrollada en Flask sobre un servidor Apache2, utilizando el módulo mod_wsgi para integrar la aplicación Python con el servidor web.
El entorno se ejecuta dentro de una máquina virtual gestionada por Vagrant, lo que permite una configuración reproducible y automatizada para entornos de desarrollo o pruebas.

## 1. Levantamiento del entorno con Vagrant

El primer paso consiste en iniciar y aprovisionar la máquina virtual mediante el comando:

vagrant up


Este proceso configurará automáticamente el entorno base sobre el cual se desplegará la aplicación.

## 2. Instalación de Apache2 y mod_wsgi

Una vez que la máquina virtual esté en ejecución, accede a ella mediante:

vagrant ssh


Luego, instala el servidor Apache2 y el módulo mod_wsgi para Python 3:

sudo apt install apache2
sudo apt install libapache2-mod-wsgi-py3
sudo systemctl restart apache2


Esto permitirá a Apache ejecutar la aplicación Flask utilizando WSGI.

## 3. Configuración de la aplicación Flask en el servidor

Dentro de la máquina virtual, dirígete al directorio /home/vagrant y copia la carpeta de la aplicación Flask (webApp) al directorio raíz de Apache:

cd /home/vagrant
sudo cp -r webApp /var/www


Esto moverá la aplicación al entorno donde Apache podrá acceder a ella.

## 4. Creación del archivo application.wsgi

A continuación, crea el archivo WSGI dentro de la carpeta del proyecto Flask:

cd /var/www/webApp
sudo vim application.wsgi


Agrega el siguiente contenido:

#!/usr/bin/python3
import sys
import logging

logging.basicConfig(stream=sys.stderr)

sys.path.insert(0, "/var/www/")
sys.path.insert(0, "/var/www/webApp/")

from webApp.run import app as application


Este archivo le indica a Apache cómo inicializar la aplicación Flask y cuál es el punto de entrada.

## 5. Configuración del sitio en Apache

Edita el archivo de configuración por defecto de Apache para enlazar el WSGI con el servidor:

sudo vim /etc/apache2/sites-available/000-default.conf


Reemplaza el contenido por el siguiente bloque de configuración:

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


Esta configuración define un VirtualHost que ejecutará la aplicación Flask desde /var/www/webApp utilizando el proceso WSGI.

## 6. Reinicio del servicio Apache

Para aplicar los cambios y cargar la nueva configuración, reinicia el servicio Apache con:

sudo systemctl restart apache2


## Autores

Karen Lopez, Monica Chicangana, Jean Pool Esguerra, Jean Alfred Gargano
Última actualización: noviembre de 2025
