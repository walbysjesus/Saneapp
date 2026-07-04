import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saneapp_pro_nuevo/core/utils/utils.dart';

class ImageUploadWithOCR extends StatefulWidget {
  final void Function(File image) onImageSelected;
  const ImageUploadWithOCR({super.key, required this.onImageSelected});

  @override
  State<ImageUploadWithOCR> createState() => _ImageUploadWithOCRState();
}

class _ImageUploadWithOCRState extends State<ImageUploadWithOCR> {
  File? _selectedImage;
  bool _checking = false;
  String? _error;

  Future<void> _pickImage() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) {
      setState(() {
        _checking = false;
      });
      return;
    }
    final file = File(picked.path);
    final hasPhone = await Util.imageContainsPhoneNumber(file.path);
    if (hasPhone) {
      setState(() {
        _error = 'La imagen contiene nÃºmeros de contacto y no puede ser subida.';
        _checking = false;
      });
      return;
    }
    setState(() {
      _selectedImage = file;
      _checking = false;
    });
    widget.onImageSelected(file);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.image),
          label: const Text('Subir imagen'),
          onPressed: _checking ? null : _pickImage,
        ),
        if (_selectedImage != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.file(_selectedImage!, height: 120),
          ),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.red)),
        if (_checking)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}


