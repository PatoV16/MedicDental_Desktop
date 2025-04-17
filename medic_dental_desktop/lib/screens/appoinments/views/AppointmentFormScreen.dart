import 'package:flutter/material.dart';
import 'package:medic_dental_desktop/database/helper.database.dart';
import 'package:intl/intl.dart';

class AddAppointmentScreen extends StatefulWidget {
  @override
  _AddAppointmentScreenState createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  String? patientName;
  int? patientId;
  DateTime selectedDate = DateTime.now();
  String appointmentTime = '';
  int duration = 0;
  String treatment = '';
  String notes = '';
  bool isNewPatient = false;

  List<Map<String, dynamic>> _patients = [];

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    final patients = await DatabaseHelper().getAllPatients();
    setState(() {
      _patients = patients;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final appointment = {
        'patient_id': patientId,
        'patient_name': patientName,
        'date': DateFormat('yyyy-MM-dd').format(selectedDate),
        'time': appointmentTime,
        'duration': duration,
        'treatment': treatment,
        'notes': notes,
        'status': 'pendiente',
      };

      final result = await DatabaseHelper().insertAppointment(appointment);
      if (result > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cita agregada exitosamente')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Agregar Cita")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(labelText: "Seleccionar Paciente"),
                  value: patientId,
                  items: _patients.map((patient) {
                    return DropdownMenuItem<int>(
                      value: patient['id'],
                      child: Text('${patient['name']}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      patientId = value;
                      isNewPatient = value == null;

                      if (value != null) {
                        final selected = _patients.firstWhere((p) => p['id'] == value);
                        patientName = selected['name'];
                      } else {
                        patientName = null;
                      }
                    });
                  },
                  validator: (value) {
                    if (value == null && (patientName == null)) {
                      return 'Seleccione un paciente o ingrese uno nuevo';
                    }
                    return null;
                  },
                ),

                if (patientId == null) ...[
                  TextFormField(
                    decoration: InputDecoration(labelText: "Nombre del Paciente"),
                    initialValue: patientName,
                    onChanged: (value) => patientName = value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese el nombre';
                      }
                      return null;
                    },
                  ),
                  
                ],

                Row(
                  children: [
                    Text("Fecha: ${DateFormat('yyyy-MM-dd').format(selectedDate)}"),
                    IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context),
                    ),
                  ],
                ),

                // Hora de la cita
InkWell(
  onTap: () async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        appointmentTime = pickedTime.format(context);
      });
    }
  },
  child: InputDecorator(
    decoration: InputDecoration(
      labelText: 'Hora de la cita',
      border: OutlineInputBorder(),
    ),
    child: Text(
      appointmentTime.isEmpty ? 'Seleccione una hora' : appointmentTime,
      style: TextStyle(fontSize: 16),
    ),
  ),
),
if (appointmentTime.isEmpty)
  Padding(
    padding: const EdgeInsets.only(top: 8.0),
    child: Text(
      'Por favor seleccione la hora',
      style: TextStyle(color: Colors.red[700], fontSize: 12),
    ),
  ),


                TextFormField(
                  decoration: InputDecoration(labelText: "Duración en minutos"),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => duration = int.tryParse(value ?? '') ?? 0,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese la duración';
                    }
                    return null;
                  },
                ),

                TextFormField(
                  decoration: InputDecoration(labelText: "Tratamiento"),
                  onSaved: (value) => treatment = value ?? '',
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: "Notas"),
                  onSaved: (value) => notes = value ?? '',
                ),

                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text("Guardar Cita"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
