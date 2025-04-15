import 'package:flutter/material.dart';
import 'package:medic_dental_desktop/database/helper.database.dart';

class RecaudosDiariosScreen extends StatefulWidget {
  const RecaudosDiariosScreen({super.key});

  @override
  _RecaudosDiariosScreenState createState() => _RecaudosDiariosScreenState();
}

class _RecaudosDiariosScreenState extends State<RecaudosDiariosScreen> {
  List<Map<String, dynamic>> recaudosDiarios = [];
  List<Map<String, dynamic>> cuentas = [];
  String? selectedCuentaId;

  @override
  void initState() {
    super.initState();
    cargarRecaudos();
    cargarCuentas();
  }

  // Cargar las cuentas por cobrar
  Future<void> cargarCuentas() async {
    final data = await DatabaseHelper().getCuentasPorCobrar();
    setState(() {
      // Filtrar cuentas para solo incluir aquellas con saldo mayor que 0
      cuentas = data.where((cuenta) {
        final saldo = cuenta['SaldoCuenta'] is double 
          ? cuenta['SaldoCuenta'] 
          : double.tryParse(cuenta['SaldoCuenta'].toString()) ?? 0;
        return saldo > 0;
      }).toList();
      
      // Limpiar la selección si la cuenta ya no existe en la lista filtrada
      if (selectedCuentaId != null && !cuentas.any((c) => c['Id'].toString() == selectedCuentaId)) {
        selectedCuentaId = null;
      }
    });
  }

  // Cargar los recaudos diarios
  Future<void> cargarRecaudos() async {
    final data = await DatabaseHelper().getRecaudosDiarios();
    setState(() {
      recaudosDiarios = data;
    });
  }

  // Agregar un nuevo recaudo
  Future<void> agregarRecaudo() async {
    final formKey = GlobalKey<FormState>();
    double recaudo = 0;
    String concepto = '';
    String fecha = DateTime.now().toIso8601String().substring(0, 10);
    int cuentaId = 0;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Agregar Recaudo Diario'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Recaudo Diario'),
                    keyboardType: TextInputType.number,
                    validator: (val) => val == null || val.isEmpty ? 'Campo requerido' : null,
                    onSaved: (val) => recaudo = double.tryParse(val!) ?? 0,
                  ),
                  // Dropdown para seleccionar cuenta
                  DropdownButtonFormField<String>(
                    value: selectedCuentaId,
                    decoration: const InputDecoration(labelText: 'Seleccionar Cuenta'),
                    items: cuentas.map((cuenta) {
                      final saldo = cuenta['SaldoCuenta'] is double 
                        ? cuenta['SaldoCuenta'] 
                        : double.tryParse(cuenta['SaldoCuenta'].toString()) ?? 0;
                      
                      return DropdownMenuItem<String>(
                        value: cuenta['Id'].toString(),
                        child: Text('${cuenta['Paciente']} - Saldo: \$${saldo.toStringAsFixed(2)}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedCuentaId = val;
                      });
                    },
                    validator: (val) => val == null || val.isEmpty ? 'Campo requerido' : null,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Concepto'),
                    validator: (val) => val == null || val.isEmpty ? 'Campo requerido' : null,
                    onSaved: (val) => concepto = val!,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  
                  // Buscar la cuenta seleccionada
                  final cuentaSeleccionada = cuentas.firstWhere(
                    (cuenta) => cuenta['Id'].toString() == selectedCuentaId
                  );
                  
                  final data = {
                    'RecaudoDiario': recaudo,
                    'FechaCobro': fecha,
                    'Concepto': concepto,
                    'NombreCliente': cuentaSeleccionada['Paciente'],
                  };

                  // Insertar el recaudo diario
                  await DatabaseHelper().insertRecaudoDiario(data);

                  // Registra el ingreso en la tabla de movimientos
                  final ingresoData = {
                    'Fecha': fecha,
                    'Concepto': 'Ingreso por recaudo',
                    'Ingresos': recaudo,
                    'Egresos': 0,
                    'Saldo': recaudo, // El saldo se actualiza con el recaudo
                  };
                  await DatabaseHelper().insertMovimiento(ingresoData);

                  // Obtener el saldo actual y calcular el nuevo
                  final saldoActual = cuentaSeleccionada['SaldoCuenta'] is double 
                    ? cuentaSeleccionada['SaldoCuenta'] 
                    : double.tryParse(cuentaSeleccionada['SaldoCuenta'].toString()) ?? 0;
                  
                  final nuevoSaldo = saldoActual - recaudo;
                  
                  // Actualizar estado además del saldo
                  final estado = nuevoSaldo <= 0 ? 'Pagado' : 'Pendiente';
                  
                  final cuentaData = {
                    'SaldoCuenta': nuevoSaldo,
                    'Estado': estado
                  };

                  await DatabaseHelper().updateCuentaPorCobrar(cuentaSeleccionada['Id'], cuentaData);

                  // Recargar los datos
                  await cargarRecaudos();
                  await cargarCuentas();
                  
                  Navigator.pop(context);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recaudos Diarios'),
        backgroundColor: Colors.teal[800],
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: agregarRecaudo,
        icon: const Icon(Icons.add),
        label: const Text('Agregar Recaudo'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: recaudosDiarios.isEmpty
            ? const Center(child: Text('No hay recaudos registrados.'))
            : ListView.builder(
                itemCount: recaudosDiarios.length,
                itemBuilder: (context, index) {
                  final recaudo = recaudosDiarios[index];
                  return Card(
                    elevation: 5,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(recaudo['NombreCliente']),
                      subtitle: Text(recaudo['FechaCobro']),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        // Mostrar detalles del recaudo
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Detalle del Recaudo'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Cliente: ${recaudo['NombreCliente']}'),
                                Text('Concepto: ${recaudo['Concepto']}'),
                                Text('Recaudo: \$${recaudo['RecaudoDiario']}'),
                                Text('Fecha: ${recaudo['FechaCobro']}'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cerrar'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}