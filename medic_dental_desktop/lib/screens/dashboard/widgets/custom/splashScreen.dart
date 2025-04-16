import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:medic_dental_desktop/database/helper.database.dart';
import 'package:medic_dental_desktop/screens/dashboard/views/main.dashboard.dart'; // Para cargar configuración

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Map<String, dynamic>? configuracion;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  Future<void> _cargarConfiguracion() async {
    // Simulamos carga de configuración, reemplaza con tu lógica de carga de datos
    final data = await DatabaseHelper().getConfiguracion();

    if (data != null) {
      setState(() {
        configuracion = data;
      });
    }

    // Simulamos una espera para que el splash screen se vea por un tiempo
    Timer(Duration(seconds: 3), () {
      // Navegamos a la pantalla principal después del splash
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DentalDashboard()), // Cambia a la pantalla principal
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade700,
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo de la clínica si existe
                  configuracion?['logo'] != null
                      ? Image.memory(
                          base64Decode(configuracion!['logo']),
                          height: 150,
                          width: 150,
                          fit: BoxFit.cover,
                        )
                      : Icon(Icons.local_hospital, size: 150, color: Colors.white), // Si no hay logo, muestra un ícono
                  SizedBox(height: 20),
                  // Nombre de la clínica
                  Text(
                    configuracion?['nombre_empresa'] ?? 'Nombre de la Clínica',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  // Información adicional (Correo, teléfono, etc.)
                  if (configuracion != null)
                    Column(
                      children: [
                        Text(
                          configuracion?['email'] ?? 'Correo no disponible',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          configuracion?['telefono'] ?? 'Teléfono no disponible',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}
