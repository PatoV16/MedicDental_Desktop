import 'package:flutter/material.dart';
import 'package:medic_dental_desktop/database/helper.database.dart';
import 'package:medic_dental_desktop/screens/facturas/views/preview.dart';

class RecaudosDiariosScreen extends StatefulWidget {
  const RecaudosDiariosScreen({super.key});

  @override
  _RecaudosDiariosScreenState createState() => _RecaudosDiariosScreenState();
}

class _RecaudosDiariosScreenState extends State<RecaudosDiariosScreen> {
  List<Map<String, dynamic>> recaudosDiarios = [];
  List<Map<String, dynamic>> cuentas = [];
  String? selectedCuentaId;
  String fecha = DateTime.now().toIso8601String().substring(0, 10);
  final TextEditingController _fechaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fechaController.text = fecha;
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
                 TextFormField(
  controller: _fechaController, // Usa un controlador
  readOnly: true, // Para evitar que el usuario escriba manualmente
  decoration: const InputDecoration(labelText: 'Fecha'),
  validator: (val) {
    if (val == null || val.isEmpty) {
      return 'Campo requerido';
    }
    return null;
  },
  onTap: () async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _fechaController.text = picked.toIso8601String().split('T').first;
      fecha = _fechaController.text;
    }
  },
  onSaved: (val) => fecha = val!,
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
 @override
Widget build(BuildContext context) {
  // Agrupar recaudos por paciente
  Map<String, List<Map<String, dynamic>>> agrupadoPorPaciente = {};
  for (var recaudo in recaudosDiarios) {
    final paciente = recaudo['NombreCliente'];
    if (!agrupadoPorPaciente.containsKey(paciente)) {
      agrupadoPorPaciente[paciente] = [];
    }
    agrupadoPorPaciente[paciente]!.add(recaudo);
  }

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
      child: agrupadoPorPaciente.isEmpty
          ? const Center(child: Text('No hay recaudos registrados.'))
          : ListView(
              children: agrupadoPorPaciente.entries.map((entry) {
                final paciente = entry.key;
                final registros = entry.value;
                return Card(
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ExpansionTile(
                    title: Text(
                      paciente,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    children: registros.map((recaudo) {
                      return ListTile(
                        title: Text('Concepto: ${recaudo['Concepto']}'),
                        subtitle: Text('Fecha: ${recaudo['FechaCobro']}'),
                        trailing: Text('\$${recaudo['RecaudoDiario']}'),
                        onTap: () {
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
                                TextButton(
                                  onPressed: () async {
                                    final configuracion = await DatabaseHelper().getConfiguracion();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FacturaPreviewScreen(
                                          recaudo: recaudo,
                                          configuracion: configuracion,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('Factura'),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
    ),
  );
}

}