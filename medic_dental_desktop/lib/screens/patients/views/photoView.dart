import 'dart:io';

import 'package:flutter/material.dart';
import 'package:medic_dental_desktop/database/helper.database.dart';
import 'package:medic_dental_desktop/screens/patients/views/uploadPhotos.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:intl/intl.dart';

class PatientGalleryScreen extends StatefulWidget {
  final int patientId;

  const PatientGalleryScreen({super.key, required this.patientId});

  @override
  State<PatientGalleryScreen> createState() => _PatientGalleryScreenState();
}

class _PatientGalleryScreenState extends State<PatientGalleryScreen> {
  List<Map<String, dynamic>> _photos = [];
  bool _isLoading = true;
  String _viewMode = 'grid'; // 'grid' o 'list'

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() => _isLoading = true);
    
    final db = await DatabaseHelper();
    final photos = await db.getPhotosByPatient(widget.patientId);
    
    setState(() {
      _photos = photos;
      _isLoading = false;
    });
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateString; // Si hay error, devuelve el string original
    }
  }

  void _openGallery(int initialIndex) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PhotoViewGallery.builder(
              itemCount: _photos.length,
              pageController: PageController(initialPage: initialIndex),
              builder: (context, index) {
                final photo = _photos[index];
                return PhotoViewGalleryPageOptions(
                  imageProvider: FileImage(File(photo['image_path'])),
                  heroAttributes: PhotoViewHeroAttributes(tag: photo['id']),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                );
              },
              scrollPhysics: const BouncingScrollPhysics(),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              loadingBuilder: (context, event) => Center(
                child: CircularProgressIndicator(
                  value: event == null ? 0 : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
                ),
              ),
            ),
            // Panel de información
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.all(16),
                child: StatefulBuilder(
                  builder: (context, setState) {
                    // Usamos StatefulBuilder para actualizar el índice
                    PageController pageController = PageController(initialPage: initialIndex);
                    int currentIndex = initialIndex;
                    
                    // Escuchar cambios de página
                    pageController.addListener(() {
                      if (pageController.page?.round() != currentIndex) {
                        setState(() {
                          currentIndex = pageController.page!.round();
                        });
                      }
                    });
                    
                    final photo = _photos[currentIndex];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(photo['date']),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          photo['description'] ?? 'Sin descripción',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            // Botones de control
            Positioned(
              top: 40,
              right: 20,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _editDescription(_photos[initialIndex]);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _deletePhoto(_photos[initialIndex]['id']);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoOptions(Map<String, dynamic> photo) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar descripción'),
              onTap: () {
                Navigator.pop(context);
                _editDescription(photo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar foto'),
              onTap: () {
                Navigator.pop(context);
                _deletePhoto(photo['id']);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editDescription(Map<String, dynamic> photo) async {
    final TextEditingController controller = TextEditingController(text: photo['description']);
    final newDescription = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar descripción'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Descripción'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Guardar')),
        ],
      ),
    );
    if (newDescription != null) {
      final db = await DatabaseHelper();
      await db.updatePhotoDescription(photo['id'], newDescription);
      _loadPhotos();
    }
  }

  void _deletePhoto(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Está seguro que desea eliminar esta foto? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final db = await DatabaseHelper();
      await db.deletePhoto(id);
      _loadPhotos();
    }
  }

  void _navigateToUploadPhotoScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UploadPhotoScreen(patientId: widget.patientId),
      ),
    ).then((_) {
      _loadPhotos();
    });
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.8, // Ajustar para dejar espacio a la información
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        final photo = _photos[index];
        return GestureDetector(
          onTap: () => _openGallery(index),
          onLongPress: () => _showPhotoOptions(photo),
          child: Card(
            elevation: 4,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Hero(
                    tag: photo['id'],
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: FileImage(File(photo['image_path'])),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(photo['date']),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (photo['description'] != null && photo['description'].toString().isNotEmpty)
                        Text(
                          photo['description'],
                          style: const TextStyle(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        final photo = _photos[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 4,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: InkWell(
            onTap: () => _openGallery(index),
            onLongPress: () => _showPhotoOptions(photo),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: photo['id'],
                  child: Image.file(
                    File(photo['image_path']),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDate(photo['date']),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _editDescription(photo),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                onPressed: () => _deletePhoto(photo['id']),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        photo['description'] ?? 'Sin descripción',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galería del paciente'),
        actions: [
          // Botón para cambiar entre vista de cuadrícula y lista
          IconButton(
            icon: Icon(_viewMode == 'grid' ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == 'grid' ? 'list' : 'grid';
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.photo_library, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay fotos disponibles',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('Agregar primera foto'),
                        onPressed: _navigateToUploadPhotoScreen,
                      ),
                    ],
                  ),
                )
              : _viewMode == 'grid' ? _buildGridView() : _buildListView(),
      floatingActionButton: _photos.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: _navigateToUploadPhotoScreen,
              child: const Icon(Icons.add_a_photo),
            ),
    );
  }
}