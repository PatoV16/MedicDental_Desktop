import 'package:flutter/material.dart';
import 'package:medic_dental_desktop/database/helper.database.dart';

class PatientFormScreen extends StatefulWidget {
  final Map<String, dynamic>? patient;

  const PatientFormScreen({Key? key, this.patient}) : super(key: key);

  @override
  _PatientFormScreenState createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _data = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    if (widget.patient != null) {
      _data.addAll(widget.patient!);
    } else {
      _data['created_at'] = DateTime.now().toIso8601String();
    }
  }

  void _savePatient() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (widget.patient == null) {
        await DatabaseHelper().insertPatient(_data);
      } else {
        await DatabaseHelper().updatePatient(widget.patient!['id'], _data);
      }
      Navigator.pop(context);
    }
  }

  Widget _buildTextField(String label, String key, {bool optional = false}) {
    return TextFormField(
      initialValue: _data[key] ?? '',
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (!optional && (value == null || value.isEmpty)) {
          return 'Este campo es obligatorio';
        }
        return null;
      },
      onSaved: (value) => _data[key] = value ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patient == null ? 'Nuevo Paciente' : 'Editar Paciente'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField('Nombre', 'name'),
              _buildTextField('Correo electrónico', 'email', optional: true),
              _buildTextField('Teléfono', 'phone', optional: true),
              _buildTextField('Dirección', 'address', optional: true),
              _buildTextField('Fecha de nacimiento', 'birthdate', optional: true),
              _buildTextField('Notas', 'notes', optional: true),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _savePatient,
                child: Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
