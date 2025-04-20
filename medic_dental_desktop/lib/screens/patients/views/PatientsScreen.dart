import 'package:flutter/material.dart';
import 'package:medic_dental_desktop/database/helper.database.dart';
import 'package:medic_dental_desktop/screens/patients/views/PatientFormScreen.dart';
import 'package:medic_dental_desktop/screens/patients/views/photoView.dart';

class PatientsScreen extends StatefulWidget {
  @override
  _PatientsScreenState createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
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
void _openPatientForm(BuildContext context, {Map<String, dynamic>? patient}) {
  showDialog(
    context: context,
    builder: (context) => PatientFormScreen(patient: patient),
  );
}

  void _navigateToForm([Map<String, dynamic>? patient]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientFormScreen(patient: patient),
      ),
    );
    _loadPatients(); // Refresh after returning
  }

  void _deletePatient(int id) async {
    await DatabaseHelper().deletePatient(id);
    _loadPatients();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(
  title: const Text("Pacientes"),
  backgroundColor: Colors.teal,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      bottom: Radius.circular(20), // Redondea la parte inferior
    ),
  ),
),
      body: ListView.builder(
        itemCount: _patients.length,
        itemBuilder: (_, index) {
          final p = _patients[index];
          return ListTile(
  title: Text(p['name']),
  subtitle: Text(p['phone'] ?? 'Sin teléfono'),
  onTap: () => _navigateToForm(p),
  trailing: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        icon: Icon(Icons.photo_library),
        onPressed: () => _openPhotoGallery(p['id']), // Abre la galería del paciente
      ),
      IconButton(
        icon: Icon(Icons.delete),
        onPressed: () => _deletePatient(p['id']),
      ),
    ],
  ),
);

        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: ()  => _openPatientForm(context),
      ),
    );
  }
  void _openPhotoGallery(int patientId) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PatientGalleryScreen(patientId: patientId),
    ),
  );
}

}
