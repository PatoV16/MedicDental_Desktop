import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Para elegir imágenes desde la galería
import 'package:medic_dental_desktop/database/helper.database.dart';

class UploadPhotoScreen extends StatefulWidget {
  final int patientId;

  const UploadPhotoScreen({super.key, required this.patientId});

  @override
  _UploadPhotoScreenState createState() => _UploadPhotoScreenState();
}

class _UploadPhotoScreenState extends State<UploadPhotoScreen> {
  final _descriptionController = TextEditingController();
  XFile? _image;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = pickedFile;
    });
  }

  Future<void> _uploadPhoto() async {
    if (_image != null && _descriptionController.text.isNotEmpty) {
      final db = await DatabaseHelper();
      final date = DateTime.now();
      await db.insertPhoto({
        'patient_id': widget.patientId,
        'image_path': _image!.path,
        'description': _descriptionController.text,
        'date': date.toIso8601String(),
      });
      Navigator.pop(context); // Cerrar pantalla después de subir
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Subir Foto')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_image != null)
              Image.file(
                File(_image!.path),
                height: 200,
                width: 200,
                fit: BoxFit.cover,
              ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Descripción de la foto'),
            ),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Elegir Foto'),
            ),
            ElevatedButton(
              onPressed: _uploadPhoto,
              child: Text('Subir Foto'),
            ),
          ],
        ),
      ),
    );
  }
}
