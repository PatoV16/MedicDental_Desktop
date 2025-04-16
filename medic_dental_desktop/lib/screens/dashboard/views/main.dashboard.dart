import 'package:flutter/material.dart';
import 'package:medic_dental_desktop/screens/dashboard/widgets/navbar/DrawerItemTile.widget.dart';
import 'package:medic_dental_desktop/screens/info/views/InformationScreen.dart';

class DentalDashboard extends StatefulWidget {
  @override
  _DentalDashboardState createState() => _DentalDashboardState();
}

class _DentalDashboardState extends State<DentalDashboard> {
  Widget _currentPage = InformacionClinicaScreen(); // Página de información predeterminada


  final List<Widget> _pages = [
    Center(child: Text("Citas")),
    Center(child: Text("Pacientes")),
    Center(child: Text("Odontogramas")),
    Center(child: Text("Inventario")),
    Center(child: Text("Cuentas")),
    Center(child: Text("Configuración")),
  ];

  void _onPageSelected(Widget page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clínica Dental'),
        backgroundColor: Colors.teal[700],
        // Remove drawer hamburger icon since we're using the sidebar
        automaticallyImplyLeading: false,
      ),
      body: Row(
        children: [
          // Left sidebar
          ExpandableSidebar(onItemSelected: _onPageSelected),
          
          // Main content area
          Expanded(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: _currentPage,
            ),
          ),
        ],
      ),
    );
  }
}