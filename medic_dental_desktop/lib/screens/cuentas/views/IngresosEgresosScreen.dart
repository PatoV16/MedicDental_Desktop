import 'package:flutter/material.dart';
import 'package:medic_dental_desktop/database/helper.database.dart';

class IngresosEgresosScreen extends StatefulWidget {
  const IngresosEgresosScreen({super.key});

  @override
  State<IngresosEgresosScreen> createState() => _IngresosEgresosScreenState();
}

class _IngresosEgresosScreenState extends State<IngresosEgresosScreen> {
  List<Map<String, dynamic>> movimientos = [];
  TextEditingController searchController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      filtrarMovimientos();
    });
    cargarMovimientos();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> cargarMovimientos() async {
    final data = await DatabaseHelper().getMovimientos();
    setState(() {
      movimientos = data;
    });
  }

  double calcularSaldo() {
    double ingresos = movimientos.fold(0, (sum, m) => sum + (m['Ingresos'] ?? 0));
    double egresos = movimientos.fold(0, (sum, m) => sum + (m['Egresos'] ?? 0));
    return ingresos - egresos;
  }

  Future<void> eliminarMovimiento(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: const Text('¿Estás seguro de que deseas eliminar este registro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper().deleteMovimiento(id);
      await cargarMovimientos();
    }
  }

  Future<void> agregarMovimiento(bool esIngreso) async {
    final formKey = GlobalKey<FormState>();
    String concepto = '';
    double valor = 0;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(esIngreso ? 'Agregar Ingreso' : 'Agregar Egreso'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Concepto'),
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                onSaved: (val) => concepto = val!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Valor'),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                onSaved: (val) => valor = double.tryParse(val!) ?? 0,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                final now = DateTime.now().toIso8601String();
                final movimiento = {
                  'Fecha': now,
                  'Concepto': concepto,
                  'Ingresos': esIngreso ? valor : 0,
                  'Egresos': esIngreso ? 0 : valor,
                };
                await DatabaseHelper().insertMovimiento(movimiento);
                await cargarMovimientos();
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void filtrarMovimientos() {
    final query = searchController.text.toLowerCase();
    setState(() {
      movimientos = movimientos.where((m) {
        final matchesSearch = m['Concepto'].toString().toLowerCase().contains(query);
        final matchesStartDate = startDate == null || DateTime.parse(m['Fecha']).isAfter(startDate!.subtract(const Duration(days: 1)));
        final matchesEndDate = endDate == null || DateTime.parse(m['Fecha']).isBefore(endDate!.add(const Duration(days: 1)));
        return matchesSearch && matchesStartDate && matchesEndDate;
      }).toList();
    });
  }

  Future<void> seleccionarRangoFechas(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      filtrarMovimientos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final saldo = calcularSaldo();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingresos y Egresos'),
        backgroundColor: Colors.blueGrey[900],
        centerTitle: true,
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: () => agregarMovimiento(true),
            label: const Text("Agregar Ingreso"),
            icon: const Icon(Icons.add),
            backgroundColor: Colors.green,
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            onPressed: () => agregarMovimiento(false),
            label: const Text("Agregar Egreso"),
            icon: const Icon(Icons.remove),
            backgroundColor: Colors.redAccent,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Buscar por concepto',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => seleccionarRangoFechas(context),
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Filtrar por fecha'),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: saldo >= 0 ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: saldo >= 0 ? Colors.green : Colors.red),
            ),
            child: Text(
              'Saldo: \$${saldo.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: saldo >= 0 ? Colors.green[800] : Colors.red[800],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.blueGrey.shade100),
                columns: const [
                  DataColumn(label: Text('Fecha')),
                  DataColumn(label: Text('Concepto')),
                  DataColumn(label: Text('Ingreso')),
                  DataColumn(label: Text('Egreso')),
                  DataColumn(label: Text('Acción')),
                ],
                rows: movimientos.map((m) {
                  return DataRow(cells: [
                    DataCell(Text(m['Fecha'].toString().substring(0, 10))),
                    DataCell(Text(m['Concepto'].toString())),
                    DataCell(Text('\$${m['Ingresos']}')),
                    DataCell(Text('\$${m['Egresos']}')),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => eliminarMovimiento(m['Id']),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
