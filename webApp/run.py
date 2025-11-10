from flask import Flask, render_template, request, g
from webApp.config import Config
from webApp.productos.controllers.producto_controller import producto_controller
from webApp.db import db
from webApp.utils.metrics import (
    http_requests_total,
    http_request_duration_seconds,
    active_connections,
    app_info
)
from prometheus_client import generate_latest, CONTENT_TYPE_LATEST
import time



def create_app():
    app = Flask(__name__, 
             template_folder='productos/web/templates', 
             static_folder='productos/web/static')

    app.config.from_object(Config)
    db.init_app(app)

    # Establecer información de la aplicación
    app_info.labels(version='1.0.0', environment='production').set(1)

    # ===================================
    # MIDDLEWARE PARA MÉTRICAS
    # ===================================
    
    @app.before_request
    def before_request_metrics():
        """Registrar inicio de petición"""
        g.start_time = time.time()
        active_connections.inc()

    @app.after_request
    def after_request_metrics(response):
        """Registrar fin de petición y métricas"""
        
        # Registrar duración de la petición
        if hasattr(g, 'start_time'):
            duration = time.time() - g.start_time
            http_request_duration_seconds.labels(
                method=request.method,
                endpoint=request.endpoint or 'unknown'
            ).observe(duration)
        
        # Registrar contador de peticiones
        http_requests_total.labels(
            method=request.method,
            endpoint=request.endpoint or 'unknown',
            status=response.status_code
        ).inc()
        
        active_connections.dec()
        
        return response

    # ===================================
    # ENDPOINTS DE MÉTRICAS Y SALUD
    # ===================================
    
    @app.route('/metrics')
    def metrics():
        """Endpoint para que Prometheus recolecte métricas"""
        return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

    @app.route('/health')
    def health():
        """Endpoint de salud para monitoreo"""
        try:
            # Verificar conexión a la base de datos
            db.session.execute('SELECT 1')
            db_status = 'healthy'
        except Exception as e:
            db_status = f'unhealthy: {str(e)}'
        
        return {
            'status': 'healthy' if db_status == 'healthy' else 'degraded',
            'database': db_status,
            'timestamp': time.time()
        }

    # ===================================
    # REGISTRAR BLUEPRINTS
    # ===================================
    
    app.register_blueprint(producto_controller)

    # ===================================
    # RUTAS PRINCIPALES
    # ===================================
    
    @app.route('/')
    def index():
        return render_template('index.html')

    @app.route('/productos')
    def productos():
        return render_template('productos.html')

    return app


# Crear la aplicación
app = create_app()


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)