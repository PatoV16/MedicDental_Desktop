import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:medic_dental_desktop/database/helper.database.dart';

class OdontogramaScreen extends StatefulWidget {
  final String pacienteId;
  final String pacienteNombre;
  final int? odontogramaId; // Opcional: si se proporciona, carga un odontograma específico

  const OdontogramaScreen({
    Key? key,
    required this.pacienteId,
    required this.pacienteNombre,
    this.odontogramaId,
  }) : super(key: key);

  @override
  _OdontogramaScreenState createState() => _OdontogramaScreenState();
}

class _OdontogramaScreenState extends State<OdontogramaScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Map<String, dynamic>? _odontograma;
  Map<String, String> _dientesEstado = {};
  final TextEditingController _observacionesController = TextEditingController();
  final TextEditingController _especificacionesController = TextEditingController();
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isHistorico = false;

  // Estados posibles para los dientes
  final List<Map<String, dynamic>> _estadosDiente = [
    {'estado': 'sano', 'color': Colors.white},
    {'estado': 'caries', 'color': Colors.red},
    {'estado': 'obturado', 'color': Colors.blue},
    {'estado': 'ausente', 'color': Colors.black26},
    {'estado': 'corona', 'color': Colors.amber},
    {'estado': 'puente', 'color': Colors.purple},
    {'estado': 'implante', 'color': Colors.teal},
  ];
  
  String _estadoSeleccionado = 'sano';

  @override
  void initState() {
    super.initState();
    _isHistorico = widget.odontogramaId != null;
    _cargarOdontograma();
  }

  Future<void> _cargarOdontograma() async {
    try {
      Map<String, dynamic>? odontogramaData;
      
      if (widget.odontogramaId != null) {
        // Cargar un odontograma específico por ID
        odontogramaData = await _dbHelper.getOdontograma(widget.odontogramaId!);
      } else {
        // Cargar el último odontograma del paciente
        odontogramaData = await _dbHelper.getLatestPatientOdontograma(widget.pacienteId);
      }
      
      setState(() {
        _odontograma = odontogramaData;
        if (_odontograma != null) {
          _dientesEstado = Map<String, String>.from(
            json.decode(_odontograma!['dientes_estado'])
          );
          _observacionesController.text = _odontograma!['observaciones'] ?? '';
          _especificacionesController.text = _odontograma!['especificaciones'] ?? '';
        } else {
          // Inicializar con un odontograma vacío (todos los dientes sanos)
          _inicializarDientesVacios();
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar el odontograma: $e');
      setState(() {
        _isLoading = false;
        _inicializarDientesVacios();
      });
    }
  }

  void _inicializarDientesVacios() {
    // Inicializar todos los dientes como sanos
    for (int i = 11; i <= 48; i++) {
      if (!_esNumeroDienteValido(i)) continue;
      _dientesEstado[i.toString()] = 'sano';
    }
  }

  bool _esNumeroDienteValido(int numero) {
    int cuadrante = numero ~/ 10;
    int posicion = numero % 10;
    
    // Verificar que sea un cuadrante válido (1-4)
    if (cuadrante < 1 || cuadrante > 4) return false;
    
    // Verificar que sea una posición válida (1-8)
    if (posicion < 1 || posicion > 8) return false;
    
    return true;
  }

  Future<void> _guardarOdontograma() async {
    try {
      Map<String, dynamic> nuevoOdontograma = {
        'cliente_id': widget.pacienteId,
        'fecha_registro': DateTime.now().toIso8601String(),
        'doctor_id': 'doc123', // Aquí deberías usar el ID del doctor actual
        'especificaciones': _especificacionesController.text,
        'observaciones': _observacionesController.text,
        'dientes_estado': json.encode(_dientesEstado),
      };

      if (_odontograma == null) {
        // Crear nuevo odontograma
        await _dbHelper.insertOdontograma(nuevoOdontograma);
      } else if (!_isHistorico) {
        // Actualizar odontograma existente (solo si no es histórico)
        await _dbHelper.updateOdontograma(_odontograma!['id'], nuevoOdontograma);
      } else {
        // Si es histórico, crear una copia actualizada
        await _dbHelper.insertOdontograma(nuevoOdontograma);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Se ha creado una nueva versión del odontograma')),
        );
      }

      setState(() {
        _isEditing = false;
      });
      
      // Recargar el odontograma
      _cargarOdontograma();
      
    } catch (e) {
      print('Error al guardar el odontograma: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar el odontograma')),
      );
    }
  }

  Color _obtenerColorDiente(String numeroDiente) {
    String estado = _dientesEstado[numeroDiente] ?? 'sano';
    Map<String, dynamic>? estadoInfo = _estadosDiente.firstWhere(
      (e) => e['estado'] == estado,
      orElse: () => {'estado': 'sano', 'color': Colors.white},
    );
    return estadoInfo['color'];
  }

  void _cambiarEstadoDiente(String numeroDiente) {
    if (!_isEditing) return;
    
    setState(() {
      _dientesEstado[numeroDiente] = _estadoSeleccionado;
    });
  }

  @override
  Widget build(BuildContext context) {
    String titulo = 'Odontograma - ${widget.pacienteNombre}';
    if (_isHistorico && _odontograma != null) {
      DateTime fecha = DateTime.tryParse(_odontograma!['fecha_registro']) ?? DateTime.now();
      String fechaFormateada = '${fecha.day}/${fecha.month}/${fecha.year}';
      titulo = 'Odontograma (${fechaFormateada}) - ${widget.pacienteNombre}';
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        actions: [
          if (!_isEditing && !_isHistorico)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else if (_isEditing)
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _guardarOdontograma,
            ),
          if (_isHistorico && !_isEditing)
            IconButton(
              icon: Icon(Icons.edit_document),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                  _isHistorico = false; // Al editar un registro histórico, se creará uno nuevo
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Al guardar se creará una nueva versión')),
                );
              },
              tooltip: 'Crear nueva versión',
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isEditing)
                    _construirSelectorEstado(),
                  
                  SizedBox(height: 20),
                  
                  // Odontograma superior (Cuadrantes 1 y 2)
                  _construirSeccionOdontograma(true),
                  
                  SizedBox(height: 40),
                  
                  // Odontograma inferior (Cuadrantes 3 y 4)
                  _construirSeccionOdontograma(false),
                  
                  SizedBox(height: 30),
                  
                  // Campos de texto para observaciones y especificaciones
                  Text(
                    'Especificaciones:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  TextField(
                    controller: _especificacionesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      enabled: _isEditing,
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  Text(
                    'Observaciones:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  TextField(
                    controller: _observacionesController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      enabled: _isEditing,
                    ),
                  ),
                  
                  if (_isHistorico && _odontograma != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Card(
                        color: Colors.blue[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Información del registro',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text('Fecha de registro: ${_odontograma!['fecha_registro']}'),
                              Text('Doctor: ${_odontograma!['doctor_id'] ?? 'No especificado'}'),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
Widget _construirSeccionOdontograma(bool superior) {
  // Cuadrantes: 1 y 2 (superior), 3 y 4 (inferior)
  List<int> cuadrantes = superior ? [1, 2] : [3, 4];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: cuadrantes.map((cuadrante) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cuadrante $cuadrante',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Wrap(
            spacing: 8.0,
            children: List.generate(8, (index) {
              int numeroDiente = cuadrante * 10 + index + 1;
              String numeroStr = numeroDiente.toString();
              return GestureDetector(
                onTap: () => _cambiarEstadoDiente(numeroStr),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _obtenerColorDiente(numeroStr),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black26),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        numeroStr,
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          SizedBox(height: 20),
        ],
      );
    }).toList(),
  );
}

  Widget _construirSelectorEstado() {
  return Card(
    elevation: 4,
    child: Padding(
      padding: EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seleccione el estado del diente:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _estadosDiente.map((estado) {
              return ChoiceChip(
                label: Text(estado['estado'].toString()),
                selected: _estadoSeleccionado == estado['estado'],
                selectedColor: estado['color'],
                onSelected: (isSelected) {
                  if (isSelected) {
                    setState(() {
                      _estadoSeleccionado = estado['estado'];
                    });
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    ),
  );
}
}