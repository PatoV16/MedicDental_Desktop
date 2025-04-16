import 'package:flutter/material.dart';
import 'package:medic_dental_desktop/database/helper.database.dart';
import 'package:medic_dental_desktop/screens/dashboard/views/main.dashboard.dart';
import 'package:medic_dental_desktop/screens/dashboard/widgets/custom/splashScreen.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/date_symbol_data_local.dart'; // <-- Importante

void main() async {
  // Inicialización para desktop
  databaseFactory = databaseFactoryFfi;

  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es_ES', null); // <-- Esta línea evita el error
  await DatabaseHelper().database;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // 👇 Aquí agregamos los delegados y locales soportad
      home: SplashScreen(),
    );
  }
}
