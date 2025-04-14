import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:medic_dental_desktop/database/helper.database.dart';
import 'package:intl/intl.dart';
import 'package:medic_dental_desktop/screens/odontograms/views/OdontogramScreen.dart';

class OdontogramaHistoryScreen extends StatefulWidget {
  final String pacienteId;
  final String pacienteNombre;

  const OdontogramaHistoryScreen({
    Key? key,
    required this.pacienteId,
    required this.pacienteNombre,
  }) : super(key: key);

  @override
  _OdontogramaHistoryScreenState createState() => _OdontogramaHistoryScreenState();
}

class _OdontogramaHistoryScreenState extends State<OdontogramaHistoryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _historialOdontogramas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final odontogramas = await _dbHelper.getPatientOdontogramas(widget.pacienteId);
      
      setState(() {
        _historialOdontogramas = odontogramas;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar historial de odontogramas: $e');
      setState(() {
        _historialOdontogramas = [];
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar el historial de odontogramas')),
      );
    }
  }

  String _contarProblemasOdontograma(String dientesEstadoJson) {
    try {
      Map<String, String> estados = Map<String, String>.from(json.decode(dientesEstadoJson));
      
      int caries = 0;
      int obturados = 0;
      int ausentes = 0;
      int otros = 0;
      
      estados.forEach((diente, estado) {
        switch (estado) {
          case 'caries':
            caries++;
            break;
          case 'obturado':
            obturados++;
            break;
          case 'ausente':
            ausentes++;
            break;
          case 'sano':
            // No contamos los sanos
            break;
          default:
            otros++;
        }
      });
      
      return 'Caries: $caries | Obturados: $obturados | Ausentes: $ausentes | Otros: $otros';
    } catch (e) {
      return 'No hay datos';
    }
  }

  String _formatearFecha(String isoFecha) {
    try {
      final fecha = DateTime.parse(isoFecha);
      return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
    } catch (e) {
      return isoFecha;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de Odontogramas - ${widget.pacienteNombre}'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _cargarHistorial,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _historialOdontogramas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medical_services_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay registros de odontogramas para este paciente',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OdontogramaScreen(
                                pacienteId: widget.pacienteId,
                                pacienteNombre: widget.pacienteNombre,
                              ),
                            ),
                          ).then((_) => _cargarHistorial());
                        },
                        child: Text('Crear primer odontograma'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _historialOdontogramas.length,
                  itemBuilder: (context, index) {
                    final odontograma = _historialOdontogramas[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OdontogramaScreen(
                                pacienteId: widget.pacienteId,
                                pacienteNombre: widget.pacienteNombre,
                                odontogramaId: odontograma['id'],
                              ),
                            ),
                          ).then((_) => _cargarHistorial());
                        },
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Fecha: ${_formatearFecha(odontograma['fecha_registro'])}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Dr. ${odontograma['doctor_id'] ?? 'No especificado'}',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                _contarProblemasOdontograma(odontograma['dientes_estado']),
                                style: TextStyle(color: Colors.blue[700]),
                              ),
                              SizedBox(height: 8),
                              if (odontograma['observaciones'] != null &&
                                  odontograma['observaciones'].toString().isNotEmpty)
                                Text(
                                  'Observaciones: ${odontograma['observaciones']}',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => OdontogramaScreen(
                                            pacienteId: widget.pacienteId,
                                            pacienteNombre: widget.pacienteNombre,
                                            odontogramaId: odontograma['id'],
                                          ),
                                        ),
                                      ).then((_) => _cargarHistorial());
                                    },
                                    child: Text('Ver detalles'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OdontogramaScreen(
                pacienteId: widget.pacienteId,
                pacienteNombre: widget.pacienteNombre,
              ),
            ),
          ).then((_) => _cargarHistorial());
        },
        child: Icon(Icons.add),
        tooltip: 'Nuevo Odontograma',
      ),
    );
  }
}