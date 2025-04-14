import 'package:flutter/material.dart';
import 'package:medic_dental_desktop/database/helper.database.dart';
import 'package:medic_dental_desktop/screens/odontograms/views/OdontogramScreen.dart';
import 'package:medic_dental_desktop/screens/odontograms/views/OdontogramsHistory.dart';

class PatientListScreen extends StatefulWidget {
  @override
  _PatientListScreenState createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _pacientes = [];
  List<Map<String, dynamic>> _pacientesFiltrados = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortField = 'name';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _cargarPacientes();
  }

  Future<void> _cargarPacientes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pacientes = await _dbHelper.getAllPatients();
      
      setState(() {
        _pacientes = pacientes;
        _aplicarFiltros();
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar pacientes: $e');
      setState(() {
        _pacientes = [];
        _pacientesFiltrados = [];
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar la lista de pacientes')),
      );
    }
  }

  void _aplicarFiltros() {
    List<Map<String, dynamic>> resultados = List.from(_pacientes);
    
    // Aplicar búsqueda
    if (_searchQuery.isNotEmpty) {
      resultados = resultados.where((paciente) {
        String nombre = '${paciente['name'] ?? ''}'.toLowerCase();
        return nombre.contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Aplicar ordenamiento
    resultados.sort((a, b) {
      dynamic valueA = a[_sortField] ?? '';
      dynamic valueB = b[_sortField] ?? '';
      
      int comparison;
      if (valueA is String && valueB is String) {
        comparison = valueA.toLowerCase().compareTo(valueB.toLowerCase());
      } else {
        comparison = valueA.toString().compareTo(valueB.toString());
      }
      
      return _sortAscending ? comparison : -comparison;
    });
    
    setState(() {
      _pacientesFiltrados = resultados;
    });
  }

  void _cambiarOrdenamiento(String campo) {
    setState(() {
      if (_sortField == campo) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = campo;
        _sortAscending = true;
      }
      _aplicarFiltros();
    });
  }

  void _navigateToOdontograma(Map<String, dynamic> paciente) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OdontogramaScreen(
          pacienteId: paciente['id'].toString(),
          pacienteNombre: paciente['name'] ?? 'Paciente',
        ),
      ),
    );
  }
  void _navigateToHistoryOdontograma(Map<String, dynamic> paciente) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OdontogramaScreen(
          pacienteId: paciente['id'].toString(),
          pacienteNombre: paciente['name'] ?? 'Paciente',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pacientes - Odontogramas'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _cargarPacientes,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Buscar paciente',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _aplicarFiltros();
                });
              },
            ),
          ),
          
          // Encabezado de la tabla
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: () => _cambiarOrdenamiento('name'),
                    child: Row(
                      children: [
                        Text(
                          'Nombre',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (_sortField == 'name')
                          Icon(
                            _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 16,
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () => _cambiarOrdenamiento('phone'),
                    child: Row(
                      children: [
                        Text(
                          'Teléfono',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (_sortField == 'phone')
                          Icon(
                            _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 16,
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () => _cambiarOrdenamiento('created_at'),
                    child: Row(
                      children: [
                        Text(
                          'Registro',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (_sortField == 'created_at')
                          Icon(
                            _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 16,
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 100), // Espacio para botones de acción
              ],
            ),
          ),
          
          // Lista de pacientes
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _pacientesFiltrados.isEmpty
                    ? Center(child: Text('No se encontraron pacientes'))
                    : ListView.builder(
                        itemCount: _pacientesFiltrados.length,
                        itemBuilder: (context, index) {
                          final paciente = _pacientesFiltrados[index];
                          return Card(
                            margin: EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 4.0,
                            ),
                            child: ListTile(
                              title: Text(
                                paciente['name'] ?? 'Sin nombre',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Tel: ${paciente['phone'] ?? 'No disponible'}'),
                                  if (paciente['email'] != null && paciente['email'].toString().isNotEmpty)
                                    Text('Email: ${paciente['email']}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.medical_services,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () => _navigateToOdontograma(paciente),
                                    tooltip: 'Ver Odontograma',
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.history,
                                      color: Colors.green,
                                    ),
                                    onPressed: () {
                                     _navigateToHistoryOdontograma(paciente);
                                      
                                    },
                                    tooltip: 'Historial de Odontogramas',
                                  ),
                                ],
                              ),
                              onTap: () => _navigateToOdontograma(paciente),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}