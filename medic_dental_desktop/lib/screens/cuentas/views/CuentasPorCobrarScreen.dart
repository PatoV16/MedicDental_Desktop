import 'package:flutter/material.dart';
import 'package:medic_dental_desktop/database/helper.database.dart';

class CuentasPorCobrarScreen extends StatefulWidget {
  const CuentasPorCobrarScreen({super.key});

  @override
  State<CuentasPorCobrarScreen> createState() => _CuentasPorCobrarScreenState();
}

class _CuentasPorCobrarScreenState extends State<CuentasPorCobrarScreen> {
  List<Map<String, dynamic>> cuentas = [];
  List<Map<String, dynamic>> cuentasFiltradas = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarCuentas();
    searchController.addListener(() {
      filtrarCuentas();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void filtrarCuentas() {
    final query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        cuentasFiltradas = List.from(cuentas);
      } else {
        cuentasFiltradas = cuentas
            .where((cuenta) =>
                cuenta['Paciente'].toString().toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> cargarCuentas() async {
    final data = await DatabaseHelper().getCuentasPorCobrar();
    setState(() {
      cuentas = data;
      cuentasFiltradas = List.from(data);
    });
  }

  Future<void> agregarCuenta() async {
    final formKey = GlobalKey<FormState>();
    String paciente = '';
    String articulo = '';
    double valorCredito = 0;
    String fechaInicial = DateTime.now().toIso8601String().substring(0, 10);
    double saldoCuenta = 0;
    List<Map<String, dynamic>> pacientes = await DatabaseHelper().getAllPatients();
    String? selectedPaciente;
    bool ingresarManual = false;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Agregar Cuenta por Cobrar'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Seleccionar Paciente'),
                      value: selectedPaciente,
                      items: [
                        ...pacientes.map((p) => DropdownMenuItem(
                              value: p['name'],
                              child: Text(p['name']),
                            )),
                        const DropdownMenuItem(
                          value: 'OTRO',
                          child: Text('Otro...'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedPaciente = value;
                          ingresarManual = value == 'OTRO';
                        });
                      },
                      validator: (val) => val == null || val.isEmpty ? 'Campo requerido' : null,
                    ),
                    if (ingresarManual)
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Nombre del Paciente'),
                        validator: (val) => val == null || val.isEmpty ? 'Campo requerido' : null,
                        onSaved: (val) => paciente = val!,
                      ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Artículo'),
                      validator: (val) => val == null || val.isEmpty ? 'Campo requerido' : null,
                      onSaved: (val) => articulo = val!,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Valor del Crédito'),
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || val.isEmpty ? 'Campo requerido' : null,
                      onSaved: (val) => valorCredito = double.tryParse(val!) ?? 0,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Saldo'),
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || val.isEmpty ? 'Campo requerido' : null,
                      onSaved: (val) => saldoCuenta = double.tryParse(val!) ?? 0,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  if (!ingresarManual) paciente = selectedPaciente!;
                  final data = {
                    'Paciente': paciente,
                    'Articulo': articulo,
                    'ValorCredito': valorCredito,
                    'FechaInicial': fechaInicial,
                    'SaldoCuenta': saldoCuenta,
                    'FechaFinal': null,
                    'Estado': saldoCuenta <= 0 ? 'Pagado' : 'Pendiente',
                  };
                  await DatabaseHelper().insertCuentaPorCobrar(data);
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

  Future<void> eliminarCuenta(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar Cuenta'),
        content: const Text('¿Estás seguro de eliminar esta cuenta por cobrar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper().deleteCuentaPorCobrar(id);
      await cargarCuentas();
    }
  }

  Widget buildEstadoIndicator(double saldo, String estado) {
    final bool estaPagado = saldo <= 0 || estado == 'Pagado';
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: estaPagado ? Colors.green : Colors.red,
      ),
      child: Center(
        child: Icon(
          estaPagado ? Icons.check : Icons.close,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuentas por Cobrar'),
        backgroundColor: Colors.teal[800],
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: agregarCuenta,
        icon: const Icon(Icons.add),
        label: const Text('Agregar Cuenta'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: 'Buscar por nombre de paciente',
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
            Expanded(
              child: cuentasFiltradas.isEmpty
                  ? const Center(child: Text('No hay cuentas registradas.'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(Colors.teal.shade100),
                        columns: const [
                          DataColumn(label: Text('Paciente')),
                          DataColumn(label: Text('Artículo')),
                          DataColumn(label: Text('Valor Crédito')),
                          DataColumn(label: Text('Saldo')),
                          DataColumn(label: Text('Fecha Inicial')),
                          DataColumn(label: Text('Estado')),
                          DataColumn(label: Text('Acción')),
                        ],
                        rows: cuentasFiltradas.map((c) {
                          final double saldo = c['SaldoCuenta'] is double
                              ? c['SaldoCuenta']
                              : double.tryParse(c['SaldoCuenta'].toString()) ?? 0;
                          final String estado = c['Estado'] ?? 'Pendiente';
                          
                          return DataRow(cells: [
                            DataCell(Text(c['Paciente'].toString())),
                            DataCell(Text(c['Articulo'].toString())),
                            DataCell(Text('\$${c['ValorCredito'].toString()}')),
                            DataCell(Text('\$${c['SaldoCuenta'].toString()}')),
                            DataCell(Text(c['FechaInicial'].toString().substring(0, 10))),
                            DataCell(Row(
                              children: [
                                buildEstadoIndicator(saldo, estado),
                                const SizedBox(width: 8),
                                Text(estado),
                              ],
                            )),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => eliminarCuenta(c['Id']),
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}