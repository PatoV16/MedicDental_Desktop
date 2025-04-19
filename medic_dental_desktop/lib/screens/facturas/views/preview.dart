import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class FacturaPreviewScreen extends StatelessWidget {
  final Map<String, dynamic> recaudo;
  final Map<String, dynamic> configuracion;
  
  const FacturaPreviewScreen({
    required this.recaudo,
    required this.configuracion,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    // Formato de moneda
    final formatoMoneda = NumberFormat.currency(
      locale: 'es_EC',
      symbol: '\$',
      decimalDigits: 2,
    );
    
    final valor = recaudo['valor'] ?? recaudo['RecaudoDiario'] ?? recaudo['Valor'] ?? 0.0;
    final nombreCliente = recaudo['nombreCliente'] ?? recaudo['NombreCliente'] ?? recaudo['ClienteNombre'] ?? 'Cliente';
    final fechaCobro = recaudo['fechaCobro'] ?? recaudo['FechaCobro'] ?? DateFormat('dd/MM/yyyy').format(DateTime.now());
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vista previa de Factura"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo (opcional)
                    if (configuracion['logo_path'] != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: Image.file(
                          File(configuracion['logo_path']),
                          height: 80,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 80,
                              width: 80,
                              color: Colors.grey[200],
                              child: const Icon(Icons.business, size: 40),
                            );
                          },
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            configuracion['nombre_empresa'] ?? 'Empresa',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
                          ),
                          const SizedBox(height: 4),
                          Text('RUC: ${configuracion['ruc'] ?? 'N/A'}'),
                          Text(configuracion['direccion'] ?? 'Dirección no especificada'),
                          if (configuracion['telefono'] != null)
                            Text('Tel: ${configuracion['telefono']}'),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.teal),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('FACTURA', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('No. 001-001-00000${recaudo['Contador'] ?? '001-001-000001'}'),
                          Text('Fecha: $fechaCobro'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DATOS DEL CLIENTE', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Nombre: $nombreCliente'),
                                if (recaudo['cedulaCliente'] != null)
                                  Text('CI/RUC: ${recaudo['cedulaCliente']}'),
                                if (recaudo['direccionCliente'] != null)
                                  Text('Dirección: ${recaudo['direccionCliente']}'),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (recaudo['telefonoCliente'] != null)
                                  Text('Teléfono: ${recaudo['telefonoCliente']}'),
                                if (recaudo['emailCliente'] != null)
                                  Text('Email: ${recaudo['emailCliente']}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('DETALLE DE FACTURA', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                        child: Row(
                          children: const [
                            Expanded(flex: 1, child: Text('CANT.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            Expanded(flex: 4, child: Text('DESCRIPCIÓN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('P. UNIT.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                            Expanded(flex: 2, child: Text('TOTAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                          ],
                        ),
                      ),
                      // Aquí normalmente iría un ListView.builder para los items
                      // Pero para este ejemplo, mostraremos un ítem fijo
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(flex: 1, child: Text('1')),
                            Expanded(flex: 4, child: Text(recaudo['descripcion'] ?? 'Pago de servicio')),
                            Expanded(flex: 2, child: Text(formatoMoneda.format(valor), textAlign: TextAlign.right)),
                            Expanded(flex: 2, child: Text(formatoMoneda.format(valor), textAlign: TextAlign.right)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Spacer(flex: 5),
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text('SUBTOTAL:', style: TextStyle(fontWeight: FontWeight.bold)),
    Text(formatoMoneda.format(valor / (1 + configuracion['iva'])), textAlign: TextAlign.right), // Subtotal antes del IVA
  ],
),
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text('IVA ${configuracion['iva'] * 100}%', style: const TextStyle(fontWeight: FontWeight.bold)),
    Text(formatoMoneda.format(valor - (valor / (1 + configuracion['iva']))), textAlign: TextAlign.right), // IVA calculado
  ],
),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    color: Colors.grey[200],
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text(formatoMoneda.format(valor), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                const Spacer(),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await generarFacturaPDF(recaudo, configuracion);
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
                )
              ],
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
  
  // Formateo de moneda para Ecuador
  final formatoMoneda = NumberFormat.currency(
    locale: 'es_EC',
    symbol: '\$',
    decimalDigits: 2,
  );
  
  // Unificar nombres de claves que pueden variar
  final valor = recaudo['valor'] ?? recaudo['RecaudoDiario'] ?? recaudo['Valor'] ?? 0.0;
  final nombreCliente = recaudo['nombreCliente'] ?? recaudo['NombreCliente'] ?? recaudo['ClienteNombre'] ?? 'Cliente';
  final fechaCobro = recaudo['fechaCobro'] ?? recaudo['FechaCobro'] ?? DateFormat('dd/MM/yyyy').format(DateTime.now());
  final subtotal = valor / 1.12;
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
                  
                  // Detalle (normalmente un for o map sobre items)
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    child: pw.Row(
                      children: [
                        pw.Expanded(flex: 1, child: pw.Text('1', style: estiloNormal)),
                        pw.Expanded(flex: 4, child: pw.Text(recaudo['descripcion'] ?? 'Pago de servicio', style: estiloNormal)),
                        pw.Expanded(flex: 2, child: pw.Text(formatoMoneda.format(subtotal), style: estiloNormal, textAlign: pw.TextAlign.right)),
                        pw.Expanded(flex: 2, child: pw.Text(formatoMoneda.format(subtotal), style: estiloNormal, textAlign: pw.TextAlign.right)),
                      ],
                    ),
                  ),
                  
                  // Totales
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
                                  pw.Text(formatoMoneda.format(subtotal), style: estiloNormal),
                                ],
                              ),
                              pw.SizedBox(height: 3),
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text('IVA ${config['iva'] * 100}%', style: estiloBold),
                                  pw.Text(formatoMoneda.format(iva), style: estiloNormal),
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
                                    pw.Text(formatoMoneda.format(valor), style: estiloBold),
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