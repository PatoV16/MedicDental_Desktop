import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:medic_dental_desktop/database/helper.database.dart';

class OdontogramaInfantilScreen extends StatefulWidget {
  final String pacienteId;
  final String pacienteNombre;
  final int? odontogramaId; // Opcional: si se proporciona, carga un odontograma específico

  const OdontogramaInfantilScreen({
    Key? key,
    required this.pacienteId,
    required this.pacienteNombre,
    this.odontogramaId,
  }) : super(key: key);

  @override
  _OdontogramaScreenState createState() => _OdontogramaScreenState();
}

class _OdontogramaScreenState extends State<OdontogramaInfantilScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Map<String, dynamic>? _odontograma;
  Map<String, String> _dientesEstado = {};
  final TextEditingController _observacionesController = TextEditingController();
  final TextEditingController _especificacionesController = TextEditingController();
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isHistorico = false;
  String _doctorActual = 'doc123'; // Esto debería venir de un sistema de login
  bool _esOdontogramaInfantil = false; // Nueva variable para determinar si es infantil

  // Estados posibles para los dientes
  final List<Map<String, dynamic>> _estadosDiente = [
    {'estado': 'sano', 'color': Colors.white, 'icon': Icons.circle_outlined},
    {'estado': 'caries', 'color': Colors.red.shade300, 'icon': Icons.dangerous},
    {'estado': 'obturado', 'color': Colors.blue.shade300, 'icon': Icons.check_circle},
    {'estado': 'ausente', 'color': Colors.black26, 'icon': Icons.cancel},
    {'estado': 'corona', 'color': Colors.amber.shade300, 'icon': Icons.brightness_7},
    {'estado': 'puente', 'color': Colors.purple.shade200, 'icon': Icons.linear_scale},
    {'estado': 'implante', 'color': Colors.teal.shade300, 'icon': Icons.architecture},
  ];
  
  String _estadoSeleccionado = 'sano';

  @override
  void initState() {
    super.initState();
    _isHistorico = widget.odontogramaId != null;

    // Determinar el tipo de odontograma según la fecha de nacimiento del paciente
    final DateTime fechaNacimiento = DateTime.tryParse(widget.pacienteId) ?? DateTime(2000);
    final int edad = DateTime.now().year - fechaNacimiento.year;
    _esOdontogramaInfantil = edad <= 12; // Considerar infantil si el paciente tiene 12 años o menos

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
    _dientesEstado.clear();
    if (_esOdontogramaInfantil) {
      // Inicializar dientes para niños (dientes temporales: 51-85)
      for (int i = 51; i <= 85; i++) {
        if (!_esNumeroDienteValido(i, infantil: true)) continue;
        _dientesEstado[i.toString()] = 'sano';
      }
    } else {
      // Inicializar dientes para adultos (dientes permanentes: 11-48)
      for (int i = 11; i <= 48; i++) {
        if (!_esNumeroDienteValido(i)) continue;
        _dientesEstado[i.toString()] = 'sano';
      }
    }
  }

  bool _esNumeroDienteValido(int numero, {bool infantil = false}) {
    if (infantil) {
      int cuadrante = numero ~/ 10;
      int posicion = numero % 10;

      // Verificar que sea un cuadrante válido (5-8 para dientes temporales)
      if (cuadrante < 5 || cuadrante > 8) return false;

      // Verificar que sea una posición válida (1-5 para dientes temporales)
      if (posicion < 1 || posicion > 5) return false;

      return true;
    } else {
      int cuadrante = numero ~/ 10;
      int posicion = numero % 10;

      // Verificar que sea un cuadrante válido (1-4 para dientes permanentes)
      if (cuadrante < 1 || cuadrante > 4) return false;

      // Verificar que sea una posición válida (1-8 para dientes permanentes)
      if (posicion < 1 || posicion > 8) return false;

      return true;
    }
  }

  Future<void> _guardarOdontograma() async {
    try {
      Map<String, dynamic> nuevoOdontograma = {
        'cliente_id': widget.pacienteId,
        'fecha_registro': DateTime.now().toIso8601String(),
        'doctor_id': _doctorActual,
        'especificaciones': _especificacionesController.text,
        'observaciones': _observacionesController.text,
        'dientes_estado': json.encode(_dientesEstado),
      };

      if (_odontograma == null) {
        // Crear nuevo odontograma
        await _dbHelper.insertOdontograma(nuevoOdontograma);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Odontograma creado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (!_isHistorico) {
        // Actualizar odontograma existente (solo si no es histórico)
        await _dbHelper.updateOdontograma(_odontograma!['id'], nuevoOdontograma);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Odontograma actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Si es histórico, crear una copia actualizada
        await _dbHelper.insertOdontograma(nuevoOdontograma);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Se ha creado una nueva versión del odontograma'),
            backgroundColor: Colors.blue,
          ),
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
        SnackBar(
          content: Text('Error al guardar el odontograma'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _obtenerColorDiente(String numeroDiente) {
    String estado = _dientesEstado[numeroDiente] ?? 'sano';
    Map<String, dynamic>? estadoInfo = _estadosDiente.firstWhere(
      (e) => e['estado'] == estado,
      orElse: () => {'estado': 'sano', 'color': Colors.white, 'icon': Icons.circle_outlined},
    );
    return estadoInfo['color'];
  }

  IconData _obtenerIconoDiente(String numeroDiente) {
    String estado = _dientesEstado[numeroDiente] ?? 'sano';
    Map<String, dynamic>? estadoInfo = _estadosDiente.firstWhere(
      (e) => e['estado'] == estado,
      orElse: () => {'estado': 'sano', 'color': Colors.white, 'icon': Icons.circle_outlined},
    );
    return estadoInfo['icon'];
  }

  void _cambiarEstadoDiente(String numeroDiente) {
    if (!_isEditing) return;
    
    setState(() {
      _dientesEstado[numeroDiente] = _estadoSeleccionado;
    });
  }

  void _alternarOdontogramaInfantil() {
    setState(() {
      _esOdontogramaInfantil = !_esOdontogramaInfantil;
      _inicializarDientesVacios(); // Reinicializar los dientes según el tipo de odontograma
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
        backgroundColor: Colors.teal[800],
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(
              _esOdontogramaInfantil ? Icons.child_care : Icons.person,
              color: Colors.white, // Cambiar el color del ícono a blanco
            ),
            tooltip: _esOdontogramaInfantil ? 'Cambiar a odontograma adulto' : 'Cambiar a odontograma infantil',
            onPressed: _alternarOdontogramaInfantil,
          ),
          if (!_isEditing && !_isHistorico)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.white), // Cambiar el color del ícono a blanco
              tooltip: 'Editar odontograma',
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else if (_isEditing)
            IconButton(
              icon: Icon(Icons.save, color: Colors.white), // Cambiar el color del ícono a blanco
              tooltip: 'Guardar cambios',
              onPressed: _guardarOdontograma,
            ),
          if (_isHistorico && !_isEditing)
            IconButton(
              icon: Icon(Icons.edit_document, color: Colors.white), // Cambiar el color del ícono a blanco
              tooltip: 'Crear nueva versión',
              onPressed: () {
                setState(() {
                  _isEditing = true;
                  _isHistorico = false; // Al editar un registro histórico, se creará uno nuevo
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Al guardar se creará una nueva versión')),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.teal.shade50],
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Panel de información del paciente
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.teal,
                              radius: 25,
                              child: Text(
                                widget.pacienteNombre.isNotEmpty 
                                    ? widget.pacienteNombre[0].toUpperCase() 
                                    : '?',
                                style: TextStyle(
                                  fontSize: 24, 
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.pacienteNombre,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _isHistorico
                                        ? 'Registro histórico'
                                        : 'Odontograma actual',
                                    style: TextStyle(
                                      color: _isHistorico ? Colors.orange : Colors.teal,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_isEditing)
                              Chip(
                                label: Text('Modo edición'),
                                backgroundColor: Colors.amber.shade100,
                                avatar: Icon(Icons.edit, size: 16),
                              ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    if (_isEditing)
                      _construirSelectorEstado(),
                    
                    SizedBox(height: 20),
                    
                    // Leyenda de estados
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Leyenda:',
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                            SizedBox(height: 8),
                            Wrap(
                              spacing: 16.0,
                              runSpacing: 8.0,
                              children: _estadosDiente.map((estado) {
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8, 
                                    vertical: 4
                                  ),
                                  decoration: BoxDecoration(
                                    color: estado['color'].withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: estado['color'],
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        estado['icon'], 
                                        color: estado['color'],
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        estado['estado'].toString(),
                                        style: TextStyle(
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 30),
                    
                    // Odontograma superior (Cuadrantes 1 y 2)
                    _construirSeccionOdontogramaKid(true),
                    
                    SizedBox(height: 40),
                    
                    // Odontograma inferior (Cuadrantes 3 y 4)
                    _construirSeccionOdontogramaKid(false),
                    
                    SizedBox(height: 30),
                    
                    // Campos de texto para especificaciones y observaciones
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      children: [
        Text(
          'Hoy:',
          style: TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.bold,
            color: Colors.teal[800],
          ),
        ),
        const SizedBox(width: 8),
        if (_isEditing)
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: Colors.teal),
            tooltip: 'Agregar fecha y hora',
            onPressed: () {
              final now = DateTime.now();
              final formatter = DateFormat('dd/MM/yyyy, HH\'h\'mm');
              final formatted = '${formatter.format(now)}.- ';
              setState(() {
                final currentText = _especificacionesController.text;
                _especificacionesController.text = '$formatted$currentText';
                _especificacionesController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _especificacionesController.text.length),
                );
              });
            },
          ),
      ],
    ),
    const SizedBox(height: 8),
    TextField(
      controller: _especificacionesController,
      maxLines: 3,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.teal.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.teal, width: 2),
        ),
        filled: true,
        fillColor: _isEditing ? Colors.white : Colors.grey.shade100,
        enabled: _isEditing,
        hintText: 'Ingrese las especificaciones...',
      ),
    ),
    const SizedBox(height: 20),
    Text(
      'Próxima Cita:',
      style: TextStyle(
        fontSize: 16, 
        fontWeight: FontWeight.bold,
        color: Colors.teal[800],
      ),
    ),
    const SizedBox(width: 8),
    if (_isEditing)
      IconButton(
        icon: Icon(Icons.add_circle_outline, color: Colors.teal),
        tooltip: 'Agregar fecha y hora a la próxima consulta',
        onPressed: () {
          final now = DateTime.now();
          final formatter = DateFormat('dd/MM/yyyy, HH\'h\'mm');
          final formatted = '${formatter.format(now)}.- ';
          setState(() {
            final currentText = _observacionesController.text;
            _observacionesController.text = '$formatted$currentText';
            _observacionesController.selection = TextSelection.fromPosition(
              TextPosition(offset: _observacionesController.text.length),
            );
          });
        },
      ),
    const SizedBox(height: 8),
    TextField(
      controller: _observacionesController,
      maxLines: 5,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.teal.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.teal, width: 2),
        ),
        filled: true,
        fillColor: _isEditing ? Colors.white : Colors.grey.shade100,
        enabled: _isEditing,
        hintText: 'Ingrese algunas observaciones...',
      ),
    ),
  ],
)
                      ),
                    ),
                    
                    if (_isHistorico && _odontograma != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Card(
                          elevation: 2,
                          color: Colors.blue[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.history, color: Colors.blue[700]),
                                    SizedBox(width: 8),
                                    Text(
                                      'Información del registro histórico',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Divider(color: Colors.blue[200]),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 16, color: Colors.blue[700]),
                                    SizedBox(width: 8),
                                    Text(
                                      'Fecha de registro: ',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(_odontograma!['fecha_registro'].toString().substring(0, 10)),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.person, size: 16, color: Colors.blue[700]),
                                    SizedBox(width: 8),
                                    Text(
                                      'Doctor: ',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(_odontograma!['doctor_id'] ?? 'No especificado'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                    // Botones de acción
                    if (_isEditing)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              icon: Icon(Icons.save),
                              label: Text('Guardar cambios'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _guardarOdontograma,
                            ),
                            SizedBox(width: 16),
                            OutlinedButton.icon(
                              icon: Icon(Icons.cancel),
                              label: Text('Cancelar'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: BorderSide(color: Colors.red),
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isEditing = false;
                                  _cargarOdontograma(); // Recargar datos originales
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _construirSeccionOdontogramaKid(bool superior) {
  List<int> cuadrantes = superior ? [8, 7] :[6, 5] ; // Se invierte para visualización más intuitiva

  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            superior ? 'Arcada Superior (Niños)' : 'Arcada Inferior (Niños)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange[800],
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: cuadrantes.map((cuadrante) {
              List<Widget> dientes = List.generate(5, (index) {
                int numeroDiente = cuadrante * 10 + (cuadrante % 2 == 0 ? index + 1 : 5 - index);

                String numeroStr = numeroDiente.toString();
                Color color = _obtenerColorDiente(numeroStr);
                IconData icon = _obtenerIconoDiente(numeroStr);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: GestureDetector(
                    onTap: () => _cambiarEstadoDiente(numeroStr),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.7),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade400, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: _isEditing ? 5 : 2,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            icon,
                            color: color == Colors.white ? Colors.grey : Colors.white,
                            size: 22,
                          ),
                          Text(
                            numeroStr,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: color == Colors.white ? Colors.black : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              });

              return Expanded(
                child: Row(
                  mainAxisAlignment: cuadrante % 2 == 0 ? MainAxisAlignment.start : MainAxisAlignment.end,
                  children: dientes,
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 150,
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Cuadrante ${cuadrantes[1]}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              Container(
                width: 150,
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Cuadrante ${cuadrantes[0]}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _construirSelectorEstado() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  'Seleccione el estado del diente:',
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              children: _estadosDiente.map((estado) {
                bool isSelected = _estadoSeleccionado == estado['estado'];
                return AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          estado['icon'],
                          size: 16,
                          color: isSelected ? Colors.white : estado['color'],
                        ),
                        SizedBox(width: 4),
                        Text(
                          estado['estado'].toString(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: estado['color'],
                    backgroundColor: estado['color'].withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected 
                            ? estado['color']
                            : estado['color'].withOpacity(0.5),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    elevation: isSelected ? 4 : 0,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    onSelected: (isSelected) {
                      if (isSelected) {
                        setState(() {
                          _estadoSeleccionado = estado['estado'];
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}