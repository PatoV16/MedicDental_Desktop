import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class FacturaPreviewScreen extends StatefulWidget {
  final Map<String, dynamic> recaudo;
  final Map<String, dynamic> configuracion;

  const FacturaPreviewScreen({
    required this.recaudo,
    required this.configuracion,
    super.key,
  });

  @override
  _FacturaPreviewScreenState createState() => _FacturaPreviewScreenState();
}

class _FacturaPreviewScreenState extends State<FacturaPreviewScreen> {
  late TextEditingController _nombreClienteController;
  late TextEditingController _cedulaClienteController;
  late TextEditingController _direccionClienteController;
  late TextEditingController _telefonoClienteController;
  late TextEditingController _emailClienteController;
  late List<Map<String, dynamic>> _servicios;

  @override
  void initState() {
    super.initState();
    _nombreClienteController = TextEditingController(text: widget.recaudo['NombreCliente'] ?? 'Cliente');
    _cedulaClienteController = TextEditingController(text: widget.recaudo['cedulaCliente'] ?? '');
    _direccionClienteController = TextEditingController(text: widget.recaudo['direccionCliente'] ?? '');
    _telefonoClienteController = TextEditingController(text: widget.recaudo['telefonoCliente'] ?? '');
    _emailClienteController = TextEditingController(text: widget.recaudo['emailCliente'] ?? '');
    _servicios = [
      {
        'descripcion': widget.recaudo['Concepto'] ?? 'Pago de servicio',
        'cantidad': 1,
        'precio': widget.recaudo['RecaudoDiario'] ?? 0.0,
      }
    ];
  }

  @override
  void dispose() {
    _nombreClienteController.dispose();
    _cedulaClienteController.dispose();
    _direccionClienteController.dispose();
    _telefonoClienteController.dispose();
    _emailClienteController.dispose();
    super.dispose();
  }

  void _agregarServicio() {
    setState(() {
      _servicios.add({'descripcion': '', 'cantidad': 1, 'precio': 0.0});
    });
  }

  void _eliminarServicio(int index) {
    setState(() {
      _servicios.removeAt(index);
    });
  }
  

  @override
  Widget build(BuildContext context) {
    final formatoMoneda = NumberFormat.currency(locale: 'es_EC', symbol: '\$');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vista previa de Factura"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DATOS DEL CLIENTE', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nombreClienteController,
                    decoration: const InputDecoration(labelText: 'Nombre del Cliente'),
                  ),
                  TextFormField(
                    controller: _cedulaClienteController,
                    decoration: const InputDecoration(labelText: 'Cédula/RUC del Cliente'),
                  ),
                  TextFormField(
                    controller: _direccionClienteController,
                    decoration: const InputDecoration(labelText: 'Dirección del Cliente'),
                  ),
                  TextFormField(
                    controller: _telefonoClienteController,
                    decoration: const InputDecoration(labelText: 'Teléfono del Cliente'),
                  ),
                  TextFormField(
                    controller: _emailClienteController,
                    decoration: const InputDecoration(labelText: 'Email del Cliente'),
                  ),
                  const SizedBox(height: 24),
                  const Text('DETALLE DE FACTURA', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _servicios.length,
                    itemBuilder: (context, index) {
                      final servicio = _servicios[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              TextFormField(
                                initialValue: servicio['descripcion'],
                                decoration: const InputDecoration(labelText: 'Descripción'),
                                onChanged: (value) => servicio['descripcion'] = value,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: servicio['cantidad'].toString(),
                                      decoration: const InputDecoration(labelText: 'Cantidad'),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) => servicio['cantidad'] = int.tryParse(value) ?? 1,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: servicio['precio'].toStringAsFixed(2),
                                      decoration: const InputDecoration(labelText: 'Precio Unitario'),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) => servicio['precio'] = double.tryParse(value) ?? 0.0,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _eliminarServicio(index),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  TextButton.icon(
                    onPressed: _agregarServicio,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Servicio'),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final recaudoEditado = {
                          'nombreCliente': _nombreClienteController.text,
                          'cedulaCliente': _cedulaClienteController.text,
                          'direccionCliente': _direccionClienteController.text,
                          'telefonoCliente': _telefonoClienteController.text,
                          'emailCliente': _emailClienteController.text,
                          'servicios': _servicios,
                        };
                        try {
                          await generarFacturaPDF(recaudoEditado, widget.configuracion);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("PDF generado exitosamente")),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error al generar PDF: $e")),
                          );
                        }
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text("Generar PDF"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> generarFacturaPDF(Map<String, dynamic> recaudo, Map<String, dynamic> config) async {
  // Crear documento PDF
  final pdf = pw.Document();
  // Funciones auxiliares para cálculos
double _calcularSubtotal(List<dynamic> servicios) {
  return servicios.fold(0.0, (sum, servicio) {
    final cantidad = servicio['cantidad'] ?? 1;
    final precio = double.tryParse(servicio['precio'].toString()) ?? 0.0;
    return sum + (cantidad * precio);
  });
}

double _calcularIVA(List<dynamic> servicios, double ivaRate) {
  final subtotal = _calcularSubtotal(servicios);
  return subtotal * ivaRate;
}

double _calcularTotal(List<dynamic> servicios, double ivaRate) {
  final subtotal = _calcularSubtotal(servicios);
  final iva = subtotal * ivaRate;
  return subtotal + iva;
}
  // Formateo de moneda para Ecuador
  final formatoMoneda = NumberFormat.currency(
    locale: 'es_EC',
    symbol: '\$',
    decimalDigits: 2,
  );
  
  // Unificar nombres de claves que pueden variar
  final valor = recaudo['RecaudoDiario'] ?? recaudo['RecaudoDiario'] ?? recaudo['RecaudoDiario'] ?? 0.0;
  final nombreCliente = recaudo['nombreCliente'] ?? recaudo['NombreCliente'] ?? 'Cliente';
  final fechaCobro =  recaudo['FechaCobro'] ?? DateFormat('dd/MM/yyyy').format(DateTime.now());
  final subtotal = valor / config['iva'];
  final iva = valor - subtotal;
  
  // Cargar logo si existe
  pw.Image? logoImage;
  try {
    if (config['logo_path'] != null && File(config['logo_path']).existsSync()) {
      final logoFile = File(config['logo_path']);
      final logoBytes = await logoFile.readAsBytes();
      logoImage = pw.MemoryImage(logoBytes) as pw.Image?;
    }
  } catch (e) {
    print('Error al cargar logo: $e');
    // Continuar sin logo
  }
  
  // Colores personalizados para el PDF
  final PdfColor colorPrimario = PdfColor.fromHex('#008080'); // Teal
  final PdfColor colorGris = PdfColor.fromHex('#F5F5F5');
  final PdfColor colorBorde = PdfColor.fromHex('#CCCCCC');
  
  // Definir estilos para reutilizar
  final estiloTitulo = pw.TextStyle(
    fontSize: 20,
    fontWeight: pw.FontWeight.bold,
    color: colorPrimario,
  );
  
  final estiloSubtitulo = pw.TextStyle(
    fontSize: 12,
    fontWeight: pw.FontWeight.bold,
    color: colorPrimario,
  );
  
  final estiloNormal = const pw.TextStyle(fontSize: 10);
  final estiloBold = pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);
  
  // Agregar página al PDF
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Encabezado con logo y datos empresa
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Logo (si existe)
                if (logoImage != null)
                  pw.Container(
                    width: 80,
                    height: 80,
                    margin: const pw.EdgeInsets.only(right: 15),
                    child: pw.Image(logoImage as pw.ImageProvider),
                  ),
                // Datos de la empresa
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(config['nombre_empresa'] ?? 'Empresa', style: estiloTitulo),
                      pw.SizedBox(height: 5),
                      pw.Text('RUC: ${config['ruc'] ?? 'N/A'}', style: estiloNormal),
                      pw.Text(config['direccion'] ?? 'Dirección no especificada', style: estiloNormal),
                      if (config['telefono'] != null)
                        pw.Text('Tel: ${config['telefono']}', style: estiloNormal),
                      if (config['email'] != null)
                        pw.Text('Email: ${config['email']}', style: estiloNormal),
                    ],
                  ),
                ),
                // Cuadro de factura
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: colorPrimario),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('FACTURA', style: estiloBold),
                      pw.SizedBox(height: 5),
                      pw.Text('No.001-001-00000 ${recaudo['Contador'] ?? '001-001-000001'}', style: estiloNormal),
                      pw.SizedBox(height: 5),
                      pw.Text('Fecha: $fechaCobro', style: estiloNormal),
                      if (config['autorizacion_sri'] != null)
                        pw.Text('Aut. SRI: ${config['autorizacion_sri']}', style: pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
              ],
            ),
            
            pw.SizedBox(height: 20),
            
            // Datos del cliente
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: colorGris,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('DATOS DEL CLIENTE', style: estiloSubtitulo),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Nombre: $nombreCliente', style: estiloNormal),
                            if (recaudo['cedulaCliente'] != null)
                              pw.Text('CI/RUC: ${recaudo['cedulaCliente']}', style: estiloNormal),
                            if (recaudo['direccionCliente'] != null)
                              pw.Text('Dirección: ${recaudo['direccionCliente']}', style: estiloNormal),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            if (recaudo['telefonoCliente'] != null)
                              pw.Text('Teléfono: ${recaudo['telefonoCliente']}', style: estiloNormal),
                            if (recaudo['emailCliente'] != null)
                              pw.Text('Email: ${recaudo['emailCliente']}', style: estiloNormal),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Detalle de factura
            pw.Text('DETALLE DE FACTURA', style: estiloSubtitulo),
            pw.SizedBox(height: 10),
            
            // Tabla de detalle
           pw.Container(
  decoration: pw.BoxDecoration(
    border: pw.Border.all(color: colorBorde),
    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
  ),
  child: pw.Column(
    children: [
      // Encabezado de tabla
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: pw.BoxDecoration(
          color: colorPrimario,
          borderRadius: const pw.BorderRadius.only(
            topLeft: pw.Radius.circular(5),
            topRight: pw.Radius.circular(5),
          ),
        ),
        child: pw.Row(
          children: [
            pw.Expanded(flex: 1, child: pw.Text('CANT.', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10))),
            pw.Expanded(flex: 4, child: pw.Text('DESCRIPCIÓN', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10))),
            pw.Expanded(flex: 2, child: pw.Text('P. UNIT.', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.right)),
            pw.Expanded(flex: 2, child: pw.Text('TOTAL', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.right)),
          ],
        ),
      ),
      
      // Detalle de servicios
      ...recaudo['servicios'].map<pw.Widget>((servicio) {
        final cantidad = servicio['cantidad'] ?? 1;
        final precio = double.tryParse(servicio['precio'].toString()) ?? 0.0;
        final total = cantidad * precio;
        
        return pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: colorBorde)),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(flex: 1, child: pw.Text(cantidad.toString(), style: estiloNormal)),
              pw.Expanded(flex: 4, child: pw.Text(servicio['descripcion'] ?? '', style: estiloNormal)),
              pw.Expanded(flex: 2, child: pw.Text(formatoMoneda.format(precio), style: estiloNormal, textAlign: pw.TextAlign.right)),
              pw.Expanded(flex: 2, child: pw.Text(formatoMoneda.format(total), style: estiloNormal, textAlign: pw.TextAlign.right)),
            ],
          ),
        );
      }).toList(),

      // Calcular totales
      pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: colorBorde)),
        ),
        padding: const pw.EdgeInsets.all(10),
        child: pw.Row(
          children: [
            pw.Expanded(flex: 5, child: pw.Container()),
            pw.Expanded(
              flex: 4,
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('SUBTOTAL:', style: estiloBold),
                      pw.Text(formatoMoneda.format(_calcularSubtotal(recaudo['servicios'])), style: estiloNormal),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('IVA ${(config['iva'] * 100).toStringAsFixed(0)}%:', style: estiloBold),
                      pw.Text(formatoMoneda.format(_calcularIVA(recaudo['servicios'], config['iva'] ?? 0.12)), style: estiloNormal),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    color: colorGris,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('TOTAL:', style: estiloBold),
                        pw.Text(formatoMoneda.format(_calcularTotal(recaudo['servicios'], config['iva'] ?? 0.12)), style: estiloBold),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  ),
),

            pw.SizedBox(height: 40),
            
            // Firmas
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 150,
                      decoration: pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(color: colorBorde)),
                      ),
                      alignment: pw.Alignment.center,
                      padding: const pw.EdgeInsets.only(top: 5),
                      child: pw.Text('Firma Autorizada', style: estiloNormal),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 150,
                      decoration: pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(color: colorBorde)),
                      ),
                      alignment: pw.Alignment.center,
                      padding: const pw.EdgeInsets.only(top: 5),
                      child: pw.Text('Firma Cliente', style: estiloNormal),
                    ),
                  ],
                ),
              ],
            ),
            
            pw.Spacer(),
            
            // Pie de página
            pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Column(
                children: [
                  pw.Text('GRACIAS POR SU CONFIANZA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  pw.SizedBox(height: 5),
                  if (config['website'] != null)
                    pw.Text(config['website'], style: pw.TextStyle(fontSize: 8, color: colorPrimario)),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
  
  // Mostrar y/o guardar el PDF
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
  );
}