import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medic_dental_desktop/screens/cuentas/views/CuentasPorCobrarScreen.dart';
import 'package:medic_dental_desktop/screens/cuentas/views/IngresosEgresosScreen.dart';
import 'package:medic_dental_desktop/screens/cuentas/views/RecaudosDiariosScreen.dart';

class CuentasScreen extends StatelessWidget {
  const CuentasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final options = [
      {
        'icon': LucideIcons.fileText,
        'title': 'Cuentas por cobrar',
        'color': Colors.indigo,
      },
     
      {
        'icon': LucideIcons.dollarSign,
        'title': 'Recaudos diarios',
        'color': Colors.green,
      },
      {
        'icon': LucideIcons.alertCircle,
        'title': 'Ingresos y egresos',
        'color': Colors.deepOrange,
      },
    ];

    return DefaultTabController( // Add DefaultTabController here
      length: options.length, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Control Financiero", selectionColor: Colors.blue),
          centerTitle: true,
          backgroundColor: const Color.fromARGB(255, 239, 241, 241),
          bottom: TabBar(
            tabs: options.map((item) {
              return Tab(
                icon: Icon(item['icon'] as IconData, color: item['color'] as Color),
                text: item['title']as String,
              );
            }).toList(),
          ),
        ),
        backgroundColor: Colors.grey[100],
        body: TabBarView(
  children: options.map((item) {
    if (item['title'] == 'Ingresos y egresos') {
      return const IngresosEgresosScreen();
    } else if (item['title'] == 'Cuentas por cobrar') {
      return const CuentasPorCobrarScreen();
    }else if (item['title'] == 'Recaudos diarios') {
      return const RecaudosDiariosScreen();
    }else {
      return Center(child: Text(item['title'] as String));
    }
  }).toList(),
)

      ),
    );
  }
}
