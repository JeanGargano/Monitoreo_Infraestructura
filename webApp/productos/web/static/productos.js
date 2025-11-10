
function getProductos() {
    fetch('/api/productos')
        .then(response => response.json())
        .then(data => {
            console.log(data);

            var productoListBody = document.querySelector('#product-list tbody');
            productoListBody.innerHTML = ''; 

            data.forEach(producto => {
                var row = document.createElement('tr');

                var idCell = document.createElement('td');
                idCell.textContent = producto.id;
                row.appendChild(idCell);

                
                var nombreCell = document.createElement('td');
                nombreCell.textContent = producto.nombre;
                row.appendChild(nombreCell);

                
                var descripcionCell = document.createElement('td');
                descripcionCell.textContent = producto.descripcion;
                row.appendChild(descripcionCell);

                
                var precioCell = document.createElement('td');
                precioCell.textContent = `$${parseFloat(producto.precio).toFixed(2)}`;
                row.appendChild(precioCell);

                
                var cantidadCell = document.createElement('td');
                cantidadCell.textContent = producto.cantidad;
                row.appendChild(cantidadCell);

                
                var categoriaCell = document.createElement('td');
                categoriaCell.textContent = producto.categoria;
                row.appendChild(categoriaCell);

                
                var actionsCell = document.createElement('td');


                
                var deleteLink = document.createElement('a');
                deleteLink.href = '#';
                deleteLink.textContent = 'Eliminar';
                deleteLink.className = 'btn btn-danger btn-sm';
                deleteLink.addEventListener('click', function() {
                    deleteProducto(producto.id);
                });
                actionsCell.appendChild(deleteLink);

                row.appendChild(actionsCell);

                productoListBody.appendChild(row);
            });
        })
        .catch(error => console.error('Error:', error));
}

function createProducto() {
    var data = {
        nombre: document.getElementById('nombre').value,
        descripcion: document.getElementById('descripcion').value,
        precio: document.getElementById('precio').value,
        cantidad: document.getElementById('cantidad').value,
        categoria: document.getElementById('categoria').value
    };

    fetch('/api/productos', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    })
    .then(response => {
        if (!response.ok) throw new Error('Network response was not ok');
        return response.json();
    })
    .then(data => {
        console.log(data);
        alert('Producto creado exitosamente');
        getProductos();
        document.getElementById('add-product-form').reset();
    })
    .catch(error => {
        console.error('Error:', error);
        alert('Error al crear producto');
    });
}


function updateProducto() {
    var productoId = document.getElementById('producto-id').value;
    var data = {
        nombre: document.getElementById('nombre').value,
        descripcion: document.getElementById('descripcion').value,
        precio: document.getElementById('precio').value,
        cantidad: document.getElementById('cantidad').value,
        categoria: document.getElementById('categoria').value
    };

    fetch(`/api/productos/${productoId}`, {
        method: 'PUT',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
    })
    .then(response => {
        if (!response.ok) {
            throw new Error('Network response was not ok');
        }
        return response.json();
    })
    .then(data => {
    
        console.log(data);
        alert('Producto actualizado exitosamente');
    
        window.location.href = '/productos';
    })
    .catch(error => {
    
        console.error('Error:', error);
        alert('Error al actualizar producto');
    });
}

function deleteProducto(productoId) {
    console.log('Deleting producto with ID:', productoId);
    if (confirm('¿Está seguro de eliminar este producto?')) {
        fetch(`/api/productos/${productoId}`, {
            method: 'DELETE',
        })
        .then(response => {
            if (!response.ok) {
                throw new Error('Network response was not ok');
            }
            return response.json();
        })
        .then(data => {
        
            console.log('Producto deleted successfully:', data);
            alert('Producto eliminado exitosamente');
        
            getProductos();
        })
        .catch(error => {
        
            console.error('Error:', error);
            alert('Error al eliminar producto');
        });
    }
}

document.addEventListener('DOMContentLoaded', function() {
    if (document.querySelector('#producto-list')) {
        getProductos();
    }
});
