import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'provider_documents_service.dart';

const _brandGreen = Color(0xFF0C4F31);
const _brandGreenSoft = Color(0xFF1E7A4B);
const _surface = Color(0xFFF6FAF7);

class TerminaTuRegistroScreen extends StatefulWidget {
  const TerminaTuRegistroScreen({super.key});

  @override
  State<TerminaTuRegistroScreen> createState() =>
      _TerminaTuRegistroScreenState();
}

class _TerminaTuRegistroScreenState extends State<TerminaTuRegistroScreen> {
  static const _allowedDocumentExtensions = ['pdf', 'jpg', 'jpeg', 'png'];
  String? rutFile;
  String? camaraFile;
  String? cedulaFile;
  String? bancarioFile;
  String? licenciaFile;
  bool termsAccepted = false;
  bool licenciaAplica = false;
  String? errorMsg;
  final ProviderDocumentsService _documentsService = ProviderDocumentsService();

  Future<void> _pickFile(Function(String) onPicked) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    final selectedFile = result?.files.single;
    final path = selectedFile?.path;
    if (selectedFile != null && path != null) {
      final extension = (selectedFile.extension ?? '').toLowerCase();
      if (!_allowedDocumentExtensions.contains(extension)) {
        setState(() {
          errorMsg = 'Formato no permitido. Usa PDF, JPG, JPEG o PNG.';
        });
        return;
      }

      final file = File(path);
      final size = await file.length();
      if (size > 10 * 1024 * 1024) {
        setState(() {
          errorMsg = 'El archivo excede el tamaño máximo de 10MB.';
        });
        return;
      }
      onPicked(path);
      setState(() {
        errorMsg = null;
      });
    }
  }

  Future<String?> _uploadFile(String? filePath, String fileName) async {
    if (filePath == null) return null;
    try {
      final documentType = _documentTypeFromFileName(fileName);
      if (documentType == null) {
        throw Exception('Tipo documental no reconocido para $fileName');
      }
      return await _documentsService.uploadDocument(filePath, documentType);
    } catch (e) {
      setState(() {
        errorMsg = 'Error al subir $fileName: $e';
      });
      return null;
    }
  }

  String? _documentTypeFromFileName(String fileName) {
    if (fileName.contains('rut')) {
      return 'rut';
    }
    if (fileName.contains('camara_comercio')) {
      return 'camara_comercio';
    }
    if (fileName.contains('cedula')) {
      return 'cedula_representante';
    }
    if (fileName.contains('certificado_bancario')) {
      return 'certificado_bancario';
    }
    if (fileName.contains('licencia_ambiental')) {
      return 'licencia_ambiental';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _brandGreen,
        title: const Text(
          'Termina tu registro',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [_brandGreen, _brandGreenSoft],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Carga documental final',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Sube tus soportes obligatorios para activar el perfil proveedor y pasar al panel operativo.',
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _UploadButton(
              label: 'Subir RUT',
              filePath: rutFile,
              onTap: () => _pickFile((path) => setState(() => rutFile = path)),
            ),
            _UploadButton(
              label: 'Subir certificado de cámara de comercio',
              filePath: camaraFile,
              onTap: () =>
                  _pickFile((path) => setState(() => camaraFile = path)),
            ),
            _UploadButton(
              label: 'Subir cédula del representante legal',
              filePath: cedulaFile,
              onTap: () =>
                  _pickFile((path) => setState(() => cedulaFile = path)),
            ),
            _UploadButton(
              label: 'Subir certificado bancario',
              filePath: bancarioFile,
              onTap: () =>
                  _pickFile((path) => setState(() => bancarioFile = path)),
            ),
            Row(
              children: [
                Checkbox(
                  value: licenciaAplica,
                  onChanged: (v) => setState(() {
                    licenciaAplica = v ?? false;
                    if (!licenciaAplica) licenciaFile = null;
                  }),
                ),
                const Expanded(child: Text('Licencia ambiental (si aplica)')),
              ],
            ),
            if (licenciaAplica)
              _UploadButton(
                label: 'Subir licencia ambiental',
                filePath: licenciaFile,
                onTap: () =>
                    _pickFile((path) => setState(() => licenciaFile = path)),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Checkbox(
                  value: termsAccepted,
                  onChanged: (v) => setState(() => termsAccepted = v ?? false),
                ),
                const Expanded(
                  child: Text('Acepto los términos y condiciones'),
                ),
              ],
            ),
            if (errorMsg != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(errorMsg!, style: TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed:
                  (rutFile != null &&
                      camaraFile != null &&
                      cedulaFile != null &&
                      bancarioFile != null &&
                      termsAccepted &&
                      (!licenciaAplica || licenciaFile != null))
                  ? () async {
                      setState(() {
                        errorMsg = null;
                      });
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) {
                        setState(() {
                          errorMsg = 'Usuario no autenticado.';
                        });
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Subiendo archivos...')),
                      );
                      final rutUrl = await _uploadFile(rutFile, 'rut.pdf');
                      final camaraUrl = await _uploadFile(
                        camaraFile,
                        'camara_comercio.pdf',
                      );
                      final cedulaUrl = await _uploadFile(
                        cedulaFile,
                        'cedula.pdf',
                      );
                      final bancarioUrl = await _uploadFile(
                        bancarioFile,
                        'certificado_bancario.pdf',
                      );
                      String? licenciaUrl;
                      if (licenciaAplica) {
                        licenciaUrl = await _uploadFile(
                          licenciaFile,
                          'licencia_ambiental.pdf',
                        );
                        if (licenciaUrl == null) {
                          setState(() {
                            errorMsg = 'Error al subir licencia ambiental.';
                          });
                          return;
                        }
                      }
                      if ([
                        rutUrl,
                        camaraUrl,
                        cedulaUrl,
                        bancarioUrl,
                      ].any((url) => url == null)) {
                        setState(() {
                          errorMsg = 'Error al subir uno o más documentos.';
                        });
                        return;
                      }
                      await FirebaseFirestore.instance
                          .collection('providers')
                          .doc(user.uid)
                          .set({
                            'rutUrl': rutUrl,
                            'camaraComercioUrl': camaraUrl,
                            'cedulaUrl': cedulaUrl,
                            'certificadoBancarioUrl': bancarioUrl,
                            'licenciaAmbientalUrl': licenciaUrl,
                            'termsAccepted': termsAccepted,
                            'profileCompleted': true,
                            'documentsStatus': 'pending_review',
                            'kycLastSubmissionAt': FieldValue.serverTimestamp(),
                            'updatedAt': FieldValue.serverTimestamp(),
                          }, SetOptions(merge: true));
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .set({
                            'profileCompleted': true,
                            'status': 'pending_review',
                            'updatedAt': FieldValue.serverTimestamp(),
                          }, SetOptions(merge: true));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Registro finalizado. Tus documentos quedan en revision administrativa.',
                          ),
                        ),
                      );
                      Navigator.pushReplacementNamed(context, '/provider_main');
                      // Opcional: cerrar pantallas anteriores
                      // Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  : null,
              child: const Text('Finalizar registro'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadButton extends StatelessWidget {
  final String label;
  final String? filePath;
  final VoidCallback onTap;

  const _UploadButton({
    required this.label,
    required this.filePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _brandGreen,
                side: const BorderSide(color: _brandGreen),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: onTap,
              child: Text(label),
            ),
          ),
          if (filePath != null)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: const Icon(Icons.check_circle, color: _brandGreenSoft),
            ),
        ],
      ),
    );
  }
}
