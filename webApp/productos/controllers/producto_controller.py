from flask import Blueprint, request, jsonify
from webApp.productos.models.producto_model import Producto
from webApp.db import db
from webApp.utils.metrics import track_crud_operation

producto_controller = Blueprint('producto_controller', __name__)

# ===============================
# API REST (JSON)
# ===============================

@producto_controller.route('/api/productos', methods=['GET'])
def get_productos():
    """API: Obtiene todos los productos en formato JSON"""
    productos = Producto.query.all()
    result = [{
        'id': producto.id,
        'nombre': producto.nombre,
        'descripcion': producto.descripcion,
        'precio': float(producto.precio),
        'cantidad': producto.cantidad,
        'categoria': producto.categoria
    } for producto in productos]

    track_crud_operation('read', 'productos') 
    return jsonify(result)


@producto_controller.route('/api/productos/<int:producto_id>', methods=['GET'])
def get_producto(producto_id):
    """API: Obtiene un producto específico por ID"""
    producto = Producto.query.get_or_404(producto_id)
    track_crud_operation('read', 'productos') 
    return jsonify({
        'id': producto.id,
        'nombre': producto.nombre,
        'descripcion': producto.descripcion,
        'precio': float(producto.precio),
        'cantidad': producto.cantidad,
        'categoria': producto.categoria
    })


@producto_controller.route('/api/productos', methods=['POST'])
def create_producto():
    """API: Crea un nuevo producto"""
    data = request.get_json(force=True)
    if not data.get('nombre') or not data.get('precio'):
        return jsonify({'error': 'Nombre y precio son requeridos'}), 400

    nuevo_producto = Producto(
        nombre=data['nombre'],
        descripcion=data.get('descripcion', ''),
        precio=data['precio'],
        cantidad=data.get('cantidad', 0),
        categoria=data.get('categoria', '')
    )
    
    db.session.add(nuevo_producto)
    db.session.commit()

    track_crud_operation('create', 'productos')
    return jsonify({
        'message': 'Producto creado exitosamente',
        'id': nuevo_producto.id
    }), 201


@producto_controller.route('/api/productos/<int:producto_id>', methods=['PUT'])
def update_producto(producto_id):
    """API: Actualiza un producto existente"""
    producto = Producto.query.get_or_404(producto_id)
    data = request.json

    producto.nombre = data['nombre']
    producto.descripcion = data.get('descripcion', '')
    producto.precio = data['precio']
    producto.cantidad = data.get('cantidad', 0)
    producto.categoria = data.get('categoria', '')

    db.session.commit()

    track_crud_operation('update', 'productos') 
    return jsonify({'message': 'Producto actualizado exitosamente'})


@producto_controller.route('/api/productos/<int:producto_id>', methods=['DELETE'])
def delete_producto(producto_id):
    """API: Elimina un producto"""
    producto = Producto.query.get_or_404(producto_id)
    db.session.delete(producto)
    db.session.commit()

    track_crud_operation('delete', 'productos')
    return jsonify({'message': 'Producto eliminado exitosamente'})
