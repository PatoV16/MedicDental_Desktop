import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Necesitas agregar esta dependencia
import 'package:image_picker/image_picker.dart';
import 'package:medic_dental_desktop/database/helper.database.dart'; // Ajusta según tu estructura

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  Map<String, dynamic>? configuracion;
  bool editando = false;
  bool isLoading = true;
  Uint8List? logoBytes;
  bool logoChanged = false;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _rucController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _ivaCntroller = TextEditingController();
  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _rucController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

 Future<void> _cargarConfiguracion() async {
  try {
    final data = await DatabaseHelper().getConfiguracion();

    setState(() {
      configuracion = data;
      isLoading = false;

      if (data != null) {
        _nombreController.text = data['nombre_empresa'] ?? '';
        _rucController.text = data['ruc'] ?? '';
        _direccionController.text = data['direccion'] ?? '';
        _telefonoController.text = data['telefono'] ?? '';
        _emailController.text = data['email'] ?? '';
        _websiteController.text = data['website'] ?? '';
        _ivaCntroller.text = data['iva'] ?? '';
        // Decodificar logo si existe
        if (data['logo'] != null && data['logo'].toString().isNotEmpty) {
          try {
            logoBytes = base64Decode(data['logo']);
          } catch (e) {
            logoBytes = null;
            debugPrint('Error al decodificar el logo: $e');
          }
        } else {
          logoBytes = null;
        }
      }
    });
  } catch (e) {
    debugPrint('Error al cargar configuración: $e');
    setState(() {
      isLoading = false;
    });
  }
}


final ImagePicker _picker = ImagePicker();
  Future<void> _seleccionarLogo() async {
  try {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final Uint8List bytes = await image.readAsBytes();
      final String base64Image = base64Encode(bytes);

      setState(() {
        logoBytes = bytes;
        logoChanged = true;
        // Esto es opcional si deseas guardar directamente el base64 desde aquí:
        // logoBase64 = base64Image;
      });
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al seleccionar imagen: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
  Future<void> _eliminarLogo() async {
    setState(() {
      logoBytes = null;
      logoChanged = true;
    });
  }

 Future<void> _guardarConfiguracion() async {
  if (_formKey.currentState!.validate()) {
    setState(() {
      isLoading = true;
    });

    // Convertir el IVA ingresado (por ejemplo, 12) a su representación decimal (0.12)
    final ivaDecimal = (double.tryParse(_ivaCntroller.text) ?? 0) / 100;

    final nuevaData = {
      'nombre_empresa': _nombreController.text,
      'ruc': _rucController.text,
      'direccion': _direccionController.text,
      'telefono': _telefonoController.text,
      'email': _emailController.text,
      'website': _websiteController.text,
      'iva': ivaDecimal.toString(), // Guardar el IVA como decimal
    };

    // Solo actualizamos el logo si ha cambiado
    if (logoChanged && logoBytes != null) {
      nuevaData['logo'] = base64Encode(logoBytes!); // Guardar como texto base64
    }

    try {
      if (configuracion == null || !configuracion!.containsKey('id')) {
        // Insertar nueva configuración
        await DatabaseHelper().insertConfiguracion(nuevaData);
      } else {
        // Actualizar configuración existente
        await DatabaseHelper().updateConfiguracion(configuracion!['id'], nuevaData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración guardada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar la configuración: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      editando = false;
      logoChanged = false;
    });
    await _cargarConfiguracion();
  }
}
  Future<void> _eliminarConfiguracion() async {
    if (configuracion != null && configuracion!.containsKey('id')) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text('¿Está seguro que desea eliminar la configuración del sistema?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() {
                  isLoading = true;
                });
                
                try {
                  await DatabaseHelper().deleteConfiguracion(configuracion!['id']);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Configuración eliminada correctamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  setState(() {
                    configuracion = null;
                    editando = false;
                    logoBytes = null;
                    logoChanged = false;
                    _formKey.currentState?.reset();
                    _nombreController.clear();
                    _rucController.clear();
                    _direccionController.clear();
                    _telefonoController.clear();
                    _emailController.clear();
                    _websiteController.clear();
                    _ivaCntroller.clear();
                  });
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar la configuración: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                
                setState(() {
                  isLoading = false;
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de la Clínica Dental'),
        backgroundColor: Colors.teal.shade700,
        elevation: 2,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.teal.shade50,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: Colors.teal.withOpacity(0.5),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: configuracion != null && !editando
                        ? _vistaConfiguracion()
                        : _formularioConfiguracion(),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _vistaConfiguracion() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: _mostrarLogo(),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              configuracion!['nombre_empresa'] ?? '',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          _cardDato('RUC', configuracion!['ruc']),
          _cardDato('Dirección', configuracion!['direccion']),
          _cardDato('Teléfono', configuracion!['telefono']),
          _cardDato('Email', configuracion!['email']),
          _cardDato('Sitio Web', configuracion!['website']),
          _cardDato('IVA', configuracion!['iva'].toString()),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Editar Configuración'),
                onPressed: () {
                  setState(() => editando = true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: const Text('Eliminar'),
                onPressed: _eliminarConfiguracion,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _mostrarLogo() {
    if (logoBytes != null) {
      return Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.teal.shade200, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.memory(
            logoBytes!,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.teal.shade200, width: 4),
        ),
        child: Icon(
          Icons.medical_services_outlined,
          size: 80,
          color: Colors.teal.shade300,
        ),
      );
    }
  }

  Widget _cardDato(String titulo, String? valor) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.teal.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              valor ?? '-',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formularioConfiguracion() {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          const SizedBox(height: 16),
          Center(
            child: _logoSelector(),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              configuracion == null ? 'Nueva Configuración' : 'Editar Configuración',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _inputTexto(
            'Nombre de la Clínica',
            _nombreController,
            icon: Icons.business,
            hint: 'Ej. Clínica Dental Sonrisas',
          ),
          _inputTexto(
            'RUC',
            _rucController,
            icon: Icons.badge,
            hint: 'Ingrese el RUC de la clínica',
          ),
          _inputTexto(
            'IVA',
            _ivaCntroller,
            icon: Icons.price_check,
            hint: 'Ingrese el IVA',
            required: false,
          ),
          _inputTexto(
            'Dirección',
            _direccionController,
            icon: Icons.location_on_outlined,
            hint: 'Dirección completa',
          ),
          _inputTexto(
            'Teléfono',
            _telefonoController,
            icon: Icons.phone_outlined,
            hint: 'Número de contacto',
          ),
          _inputTexto(
            'Email',
            _emailController,
            icon: Icons.email_outlined,
            hint: 'correo@ejemplo.com',
            isEmail: true,
          ),
          _inputTexto(
            'Sitio Web',
            _websiteController,
            icon: Icons.language_outlined,
            hint: 'www.ejemplo.com',
            required: false,
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar Cambios'),
                onPressed: _guardarConfiguracion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (configuracion != null) ...[
                const SizedBox(width: 16),
                TextButton.icon(
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar'),
                  onPressed: () {
                    setState(() {
                      editando = false;
                      logoChanged = false;
                      
                      // Restaurar los valores originales
                      _nombreController.text = configuracion!['nombre_empresa'] ?? '';
                      _rucController.text = configuracion!['ruc'] ?? '';
                      _direccionController.text = configuracion!['direccion'] ?? '';
                      _telefonoController.text = configuracion!['telefono'] ?? '';
                      _emailController.text = configuracion!['email'] ?? '';
                      _websiteController.text = configuracion!['website'] ?? '';
                      _ivaCntroller.text = (double.tryParse(configuracion!['iva'] ?? '0') ?? 0 * 100).toStringAsFixed(0);
                      
                      // Restaurar el logo
                      if (configuracion!['logo'] != null) {
                        logoBytes = configuracion!['logo'];
                      } else {
                        logoBytes = null;
                      }
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _logoSelector() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.teal.shade200, width: 3),
              ),
              child: logoBytes != null
                  ? ClipOval(
                      child: Image.memory(
                        logoBytes!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 60,
                      color: Colors.teal.shade400,
                    ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.teal.shade500,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  logoBytes == null ? Icons.add : Icons.edit,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: _seleccionarLogo,
                tooltip: 'Seleccionar logo',
              ),
            ),
          ],
        ),
        if (logoBytes != null)
          TextButton.icon(
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Eliminar logo'),
            onPressed: _eliminarLogo,
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade500,
            ),
          ),
        const SizedBox(height: 10),
        Text(
          'Logo de la Clínica',
          style: TextStyle(
            fontSize: 16,
            color: Colors.teal.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Recomendado: imagen cuadrada de 512x512px',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _inputTexto(
    String label,
    TextEditingController controller, {
    IconData? icon,
    String? hint,
    bool required = true,
    bool isEmail = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon, color: Colors.teal) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.teal),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.teal.shade700, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          labelStyle: TextStyle(color: Colors.teal.shade700),
        ),
        validator: (value) {
          if (required && (value == null || value.isEmpty)) {
            return 'Este campo es obligatorio';
          }
          if (isEmail && value!.isNotEmpty && !value.contains('@')) {
            return 'Ingrese un email válido';
          }
          return null;
        },
      ),
    );
  }
}