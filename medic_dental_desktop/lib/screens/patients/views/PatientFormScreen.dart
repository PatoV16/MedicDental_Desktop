import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  final _birthdateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.patient != null) {
      _data.addAll(widget.patient!);
      if (_data['birthdate'] != null && _data['birthdate'].toString().isNotEmpty) {
        _birthdateController.text = _data['birthdate'];
      }
    } else {
      _data['created_at'] = DateTime.now().toIso8601String();
    }
  }

  @override
  void dispose() {
    _birthdateController.dispose();
    super.dispose();
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        initialValue: _data[key] ?? '',
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (!optional && (value == null || value.isEmpty)) {
            return 'Este campo es obligatorio';
          }
          return null;
        },
        onSaved: (value) => _data[key] = value ?? '',
      ),
    );
  }

  Widget _buildDatePickerField(String label, String key) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: _birthdateController,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor selecciona una fecha';
          }
          return null;
        },
        onTap: () async {
          final initialDate = _data[key] != null
              ? DateTime.tryParse(_data[key]) ?? DateTime.now()
              : DateTime.now();
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: initialDate,
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            builder: (context, child) => Theme(
              data: ThemeData.light().copyWith(
                colorScheme: ColorScheme.light(
                  primary: Colors.teal,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
                dialogBackgroundColor: Colors.white,
              ),
              child: child!,
            ),
          );
          if (picked != null) {
            final formattedDate = DateFormat('yyyy-MM-dd').format(picked);
            setState(() {
              _birthdateController.text = formattedDate;
              _data[key] = formattedDate;
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.all(40),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.patient == null ? 'Nuevo Paciente' : 'Editar Paciente',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField('Nombre', 'name'),
                    _buildTextField('Correo electrónico', 'email', optional: true),
                    _buildTextField('Teléfono', 'phone', optional: true),
                    _buildTextField('Dirección', 'address', optional: true),
                    _buildDatePickerField('Fecha de nacimiento', 'birthdate'),
                    _buildTextField('Notas', 'notes', optional: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancelar'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _savePatient,
                    child: Text('Guardar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
