import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:medic_dental_desktop/database/helper.database.dart'; // Ajusta el import

class InformacionClinicaScreen extends StatefulWidget {
  const InformacionClinicaScreen({super.key});

  @override
  State<InformacionClinicaScreen> createState() => _InformacionClinicaScreenState();
}

class _InformacionClinicaScreenState extends State<InformacionClinicaScreen> {
  Map<String, dynamic>? configuracion;
  Uint8List? logoBytes;
  int totalPacientes = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final config = await DatabaseHelper().getConfiguracion();
    final pacientes = await DatabaseHelper().getTotalPacientes(); // debes tener este método

    setState(() {
      configuracion = config;
      totalPacientes = pacientes;
      isLoading = false;

      if (config != null && config['logo'] != null && config['logo'].toString().isNotEmpty) {
        try {
          logoBytes = base64Decode(config['logo']);
        } catch (e) {
          logoBytes = null;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text("Información del Negocio"),
  backgroundColor: Colors.teal,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      bottom: Radius.circular(20), // Redondea la parte inferior
    ),
  ),
),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Logo y nombre
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.teal.shade50,
                            backgroundImage:
                                logoBytes != null ? MemoryImage(logoBytes!) : null,
                            child: logoBytes == null
                                ? Icon(Icons.image, size: 40, color: Colors.teal.shade400)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              configuracion?['nombre_empresa'] ?? 'Sin nombre',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info de contacto
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    child: ListTile(
                      leading: const Icon(Icons.phone, color: Colors.teal),
                      title: Text(configuracion?['telefono'] ?? 'No registrado'),
                      subtitle: Text(configuracion?['email'] ?? 'Sin correo'),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Dirección
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    child: ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.teal),
                      title: const Text('Dirección'),
                      subtitle: Text(configuracion?['direccion'] ?? 'No registrada'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Estadísticas
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: Colors.teal.shade50,
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.people, color: Colors.teal),
                      title: const Text('Total de Pacientes'),
                      trailing: Text(
                        '$totalPacientes',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Otros widgets o acciones
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Otros datos',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text('Aquí puedes añadir más información como horario, sitio web, etc.'),
                          if (configuracion?['website'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                configuracion!['website'],
                                style: const TextStyle(color: Colors.blue),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
