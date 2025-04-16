import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:medic_dental_desktop/quiestion.dart';
import 'package:medic_dental_desktop/screens/appoinments/views/CalendarAppointmentsScreen.dart';
import 'package:medic_dental_desktop/screens/cuentas/views/CuentasDashboard.dart';
import 'package:medic_dental_desktop/screens/odontograms/views/OdontogramScreen.dart';
import 'package:medic_dental_desktop/screens/odontograms/views/PatientListScreen.dart';
import 'package:medic_dental_desktop/screens/patients/views/PatientsScreen.dart';
import 'package:medic_dental_desktop/screens/products/views/InventoryScreen.dart';

class ExpandableSidebar extends StatefulWidget {
  final Function(Widget) onItemSelected;

  const ExpandableSidebar({super.key, required this.onItemSelected});

  @override
  State<ExpandableSidebar> createState() => _ExpandableSidebarState();
}

class _ExpandableSidebarState extends State<ExpandableSidebar> {
  double _sidebarWidth = 70;
  bool _isExpanded = false;
  int selectedIndex = 0;

  final Map<String, Color> _itemColors = {
    'Citas': Color(0xFFFFA726),
    'Pacientes': Color(0xFFE65100),
    'Odontogramas': Color(0xFFD32F2F),
    'Inventario': Color(0xFF1976D2),
    'Cuentas': Color(0xFF039BE5),
    'Configuración': Color(0xFF7CB342),
  };

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _expandSidebar(),
      onExit: (_) => _collapseSidebar(),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        width: _sidebarWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 10),
                children: [
                  _buildSidebarItem(Icons.event, 'Citas', 0),
                  _buildSidebarItem(Icons.people, 'Pacientes', 1),
                  _buildSidebarItem(Icons.medical_services, 'Odontogramas', 2),
                  _buildSidebarItem(Icons.inventory, 'Inventario', 3),
                  _buildSidebarItem(Icons.account_balance_wallet, 'Cuentas', 4),
                  _buildSidebarItem(Icons.settings, 'Configuración', 5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, int index) {
    final color = _itemColors[title] ?? Colors.grey;
    final isSelected = selectedIndex == index;

    return AnimatedContainer(
      duration: Duration(milliseconds: 250),
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.teal.withOpacity(0.9) : color,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: Colors.white, width: 2)
            : Border.all(color: Colors.transparent),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.4),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                )
              ]
            : [],
      ),
      child: InkWell(
        onTap: () => _onItemSelected(index),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            if (_isExpanded)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _expandSidebar() {
    setState(() {
      _sidebarWidth = 150;
      _isExpanded = true;
    });
  }

  void _collapseSidebar() {
    setState(() {
      _sidebarWidth = 70;
      _isExpanded = false;
    });
  }

  void _onItemSelected(int index) {
    Widget page = Center(child: Text('Página no encontrada'));

    setState(() {
      selectedIndex = index;
    });

    switch (index) {
      case 0:
        page = CalendarAppointmentsScreen();
        break;
      case 1:
        page = PatientsScreen();
        break;
      case 2:
        page = PatientListScreen();
        break;
      case 3:
        page = InventoryScreen();
        break;
      case 4:
        page = CuentasScreen();
        break;
      case 5:
        page = Center(child: Text('Página de Configuración'));
        break;
    }

    widget.onItemSelected(page);
  }
}