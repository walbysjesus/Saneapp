import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../services/storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FinalDisposalCertificatesPage extends StatefulWidget {
  const FinalDisposalCertificatesPage({super.key});

  @override
  State<FinalDisposalCertificatesPage> createState() => _FinalDisposalCertificatesPageState();
}

class _FinalDisposalCertificatesPageState extends State<FinalDisposalCertificatesPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _wasteTypeController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  bool _loading = false;
  // File? _selectedFile; // Eliminado porque no se usa
  String? _uploadedFileUrl;
  String? _fileName;

  void _submitRequest() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    // AquÃ­ irÃ­a la lÃ³gica para guardar la solicitud en la base de datos
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud enviada correctamente.')),
      );
    });
  }

  Future<void> _pickAndUploadDocument() async {
    setState(() => _loading = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']);
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        setState(() {
          _fileName = result.files.single.name;
        });
        // Obtener el UID real del usuario autenticado
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario no autenticado.')),
          );
          return;
        }
        final uid = user.uid;
        final url = await StorageService.uploadProviderDocument(file, uid);
        setState(() {
          _uploadedFileUrl = url;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documento adjuntado y subido correctamente.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al adjuntar documento: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificados de disposiciÃ³n final'),
        backgroundColor: const Color(0xFF388E3C),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(labelText: 'Empresa'),
                validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _wasteTypeController,
                decoration: const InputDecoration(labelText: 'Tipo de residuo'),
                validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: 'Fecha'),
                validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    _dateController.text = date.toIso8601String().split('T').first;
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Enviar solicitud'),
                onPressed: _loading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF388E3C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.attach_file),
                label: const Text('Adjuntar documentos'),
                onPressed: _loading ? null : _pickAndUploadDocument,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _uploadedFileUrl != null ? Colors.green : Colors.grey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              if (_fileName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file, size: 20, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_fileName!, style: const TextStyle(fontSize: 14))),
                      if (_uploadedFileUrl != null)
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
              const Text('Estado de la solicitud: Pendiente', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Descargar certificado'),
                onPressed: () {
                  // LÃ³gica para descargar el certificado
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Descarga de certificado prÃ³ximamente.')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

