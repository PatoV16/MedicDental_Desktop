import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medic_dental_desktop/database/helper.database.dart';

class InventoryScreen extends StatefulWidget {
  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await DatabaseHelper().getAllProductos();
    setState(() => _products = products);
  }

  Future<void> _addMovementDialog(Map<String, dynamic> product) async {
    final _formKey = GlobalKey<FormState>();
    final _quantityController = TextEditingController();
    String _movementType = 'entrada';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Registrar movimiento para ${product['nombre']}'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _movementType,
                items: ['entrada', 'salida']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => _movementType = val!,
                decoration: InputDecoration(labelText: 'Tipo de movimiento'),
              ),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Cantidad'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Ingrese la cantidad' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(child: Text('Cancelar'), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            child: Text('Guardar'),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final cantidad = int.tryParse(_quantityController.text) ?? 0;
                final movimiento = {
                  'producto_id': product['id'],
                  'fecha': DateTime.now().toIso8601String(),
                  'cantidad': cantidad,
                };
                if (_movementType == 'entrada') {
                  await DatabaseHelper().insertEntrada(movimiento);
                } else {
                  await DatabaseHelper().insertSalida(movimiento);
                }
                Navigator.pop(context);
                _loadProducts();
              }
            },
          ),
        ],
      ),
    );
  }

 Future<void> _showAddProductDialog({Map<String, dynamic>? product}) async {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: product?['nombre'] ?? '');
  final _descriptionController = TextEditingController(text: product?['descripcion'] ?? '');
  final _stockController = TextEditingController(text: product?['stock']?.toString() ?? '0');
  final _priceController = TextEditingController(text: product?['precio_unitario']?.toString() ?? '0.0'); // Agregado

  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(product == null ? 'Agregar nuevo producto' : 'Editar producto'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Nombre'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Ingrese un nombre' : null,
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Descripción'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Ingrese una descripción' : null,
            ),
            TextFormField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Stock'),
              validator: (value) =>
                  value == null || value.isEmpty || int.tryParse(value) == null
                      ? 'Ingrese un valor válido para el stock'
                      : null,
            ),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Precio Unitario'),
              validator: (value) =>
                  value == null || value.isEmpty || double.tryParse(value) == null
                      ? 'Ingrese un valor válido para el precio'
                      : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(child: Text('Cancelar'), onPressed: () => Navigator.pop(context)),
        ElevatedButton(
          child: Text('Guardar'),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final data = {
                'nombre': _nameController.text,
                'descripcion': _descriptionController.text,
                'stock': int.tryParse(_stockController.text) ?? 0,
                'precio_unitario': double.tryParse(_priceController.text) ?? 0.0, // Agregado
              };
              if (product == null) {
                await DatabaseHelper().insertProducto(data);
              } else {
                await DatabaseHelper().updateProducto(product['id'], data);
              }
              Navigator.pop(context);
              _loadProducts();
            }
          },
        ),
      ],
    ),
  );
}

  Future<void> _confirmDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Eliminar producto'),
        content: Text('¿Estás seguro de eliminar este producto?'),
        actions: [
          TextButton(child: Text('Cancelar'), onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(child: Text('Eliminar'), onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper().deleteProducto(id);
      _loadProducts();
    }
  }

  Future<int> _getStock(int productId) async {
    final entradas = await DatabaseHelper().getEntradasByProducto(productId);
    final salidas = await DatabaseHelper().getSalidasByProducto(productId);
    final totalEntradas = entradas.fold<int>(0, (sum, item) => sum + (item['cantidad'] ?? 0)as int);
    final totalSalidas = salidas.fold<int>(0, (sum, item) => sum + (item['cantidad'] ?? 0)as int);
    return totalEntradas - totalSalidas;
  }

  void _showMovementsBottomSheet(Map<String, dynamic> product) async {
    final entradas = await DatabaseHelper().getEntradasByProducto(product['id']);
    final salidas = await DatabaseHelper().getSalidasByProducto(product['id']);
    final formatter = DateFormat('dd/MM/yyyy HH:mm');

    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: EdgeInsets.all(16),
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Movimientos de ${product['nombre']}', style: Theme.of(context).textTheme.titleLarge),
            Divider(),
            Expanded(
              child: ListView(
                children: [
                  ...entradas.map((e) => ListTile(
                        leading: Icon(Icons.arrow_downward, color: Colors.green),
                        title: Text('Entrada: ${e['cantidad']}'),
                        subtitle: Text(formatter.format(DateTime.parse(e['fecha']))),
                      )),
                  ...salidas.map((s) => ListTile(
                        leading: Icon(Icons.arrow_upward, color: Colors.red),
                        title: Text('Salida: ${s['cantidad']}'),
                        subtitle: Text(formatter.format(DateTime.parse(s['fecha']))),
                      )),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text("Inventario de Productos"),
  backgroundColor: Colors.teal,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      bottom: Radius.circular(20), // Redondea la parte inferior
    ),
  ),
),
      body: ListView.builder(
        itemCount: _products.length,
        itemBuilder: (_, index) {
          final product = _products[index];
          return FutureBuilder<int>(
            future: _getStock(product['id']),
            builder: (context, snapshot) {
              final stock = snapshot.data ?? 0;
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  title: Text(product['nombre']),
                  subtitle: Text('Stock actual: $stock'),
                  onTap: () => _showMovementsBottomSheet(product),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () => _addMovementDialog(product),
                        tooltip: 'Registrar entrada o salida',
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showAddProductDialog(product: product);
                          } else if (value == 'delete') {
                            _confirmDelete(product['id']);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'edit', child: Text('Editar')),
                          PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(),
        child: Icon(Icons.add),
        tooltip: 'Agregar producto',
      ),
    );
  }
}
