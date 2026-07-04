import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/widgets/role_guard.dart';
import '../supervision/supervision_artifacts.dart';
import '../../state/app_state.dart';

class SupervisorActaPage extends StatefulWidget {
  final String solicitudId;
  final bool esActaFinal;
  const SupervisorActaPage({
    super.key,
    required this.solicitudId,
    this.esActaFinal = false,
  });

  @override
  State<SupervisorActaPage> createState() => _SupervisorActaPageState();
}

class _SupervisorActaPageState extends State<SupervisorActaPage> {
  final _formKey = GlobalKey<FormState>();
  final _observacionesController = TextEditingController();
  final List<_SelectedEvidence> _evidencias = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _condicionesVerificadas = false;
  bool _cumplimientoServicio = false;
  bool _loading = false;
  bool _capturingLocation = false;
  Map<String, dynamic>? _visitLocation;

  Future<List<String>> _uploadImages(String solicitudId) async {
    final urls = <String>[];
    final requestSnapshot = await FirebaseFirestore.instance
        .collection('solicitudes')
        .doc(solicitudId)
        .get();
    final requestData = requestSnapshot.data() ?? const <String, dynamic>{};
    final orderCode = _sanitizeStorageSegment(
      requestData['supervisorOrderCode']?.toString(),
    );
    final orderFolder = orderCode ?? 'sin-codigo';
    for (var index = 0; index < _evidencias.length; index++) {
      final img = _evidencias[index];
      final extension = img.extension ?? 'jpg';
      final ref = FirebaseStorage.instance.ref().child(
        'solicitudes/$solicitudId/ordenes_supervision/$orderFolder/actas/${widget.esActaFinal ? 'final' : 'inicial'}/${DateTime.now().millisecondsSinceEpoch}_$index.$extension',
      );
      final uploadTask = await _startUpload(
        ref: ref,
        path: img.path,
        bytes: img.bytes,
      );
      await uploadTask;
      final url = await ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  Future<void> _pickEvidenceFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    final files = result?.files ?? const <PlatformFile>[];
    if (files.isEmpty || !mounted) {
      return;
    }
    setState(() {
      _evidencias.addAll(
        files.map(
          (file) => _SelectedEvidence(
            name: file.name,
            path: file.path,
            bytes: file.bytes,
            extension: file.extension,
          ),
        ),
      );
    });
  }

  Future<void> _captureEvidence() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 82,
    );
    if (file == null || !mounted) {
      return;
    }
    setState(() {
      _evidencias.add(_selectedEvidenceFromXFile(file));
    });
  }

  Future<void> _captureVisitLocation() async {
    setState(() {
      _capturingLocation = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage('Activa el GPS del dispositivo para registrar la visita.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage('No se concedió permiso de ubicación para esta visita.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final location = <String, dynamic>{
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'capturedAt': DateTime.now().toIso8601String(),
      };
      if (!mounted) {
        return;
      }
      setState(() {
        _visitLocation = location;
      });
      _showMessage('Ubicación de la visita registrada.');
    } catch (_) {
      _showMessage('No fue posible obtener la ubicación de la visita.');
    } finally {
      if (mounted) {
        setState(() {
          _capturingLocation = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickEvidenceFromGallery() async {
    final files = await _imagePicker.pickMultiImage(imageQuality: 82);
    if (files.isEmpty || !mounted) {
      return;
    }
    setState(() {
      _evidencias.addAll(files.map(_selectedEvidenceFromXFile));
    });
  }

  _SelectedEvidence _selectedEvidenceFromXFile(XFile file) {
    final fileName = file.name;
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'jpg';
    return _SelectedEvidence(
      name: fileName,
      path: file.path,
      bytes: null,
      extension: extension,
    );
  }

  Future<UploadTask> _startUpload({
    required Reference ref,
    String? path,
    Uint8List? bytes,
  }) async {
    if (path != null && path.isNotEmpty) {
      return ref.putFile(File(path));
    }
    if (bytes != null) {
      return ref.putData(bytes);
    }
    throw Exception('No file data available for upload');
  }

  Future<void> _guardarActa() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    try {
      final requestSnapshot = await FirebaseFirestore.instance
          .collection('solicitudes')
          .doc(widget.solicitudId)
          .get();
      final requestData = requestSnapshot.data() ?? <String, dynamic>{};
      final urls = await _uploadImages(widget.solicitudId);
      final now = DateTime.now();
      final notes = _observacionesController.text.trim();
        final supervisorOrderCode =
          requestData['supervisorOrderCode']?.toString();
      final actaData = widget.esActaFinal
          ? {
              'fecha': now.toIso8601String(),
              'cumplimientoServicio': _cumplimientoServicio,
              'observacionesFinales': notes,
              'imagenesFinales': urls,
              'visitLocation': _visitLocation,
              'firmaDigital': false,
              'supervisorId': user.uid,
              'supervisorOrderCode': supervisorOrderCode,
            }
          : {
              'fecha': now.toIso8601String(),
              'supervisorId': user.uid,
              'observaciones': notes,
              'listaImagenesUrls': urls,
              'visitLocation': _visitLocation,
              'condicionesInicialesVerificadas': _condicionesVerificadas,
              'firmaDigital': false,
              'supervisorOrderCode': supervisorOrderCode,
            };

      final updatePayload = <String, dynamic>{
        widget.esActaFinal ? 'actaFinal' : 'actaInicial': actaData,
        'supervisorStatus': widget.esActaFinal ? 'finalizado' : 'verificado',
        'supervisorStatusUpdatedAt': FieldValue.serverTimestamp(),
        'lastSupervisorVisitLocation': _visitLocation,
      };

      if (widget.esActaFinal) {
        final evaluation =
            resolveProviderQualityEvaluation(requestData) ??
            buildInitialProviderQualityEvaluation();
        final existingEvidence =
            (evaluation['evidenceUrls'] as List?)
                ?.map((item) => item.toString())
                .toList() ??
            <String>[];
        final incidentNotes = notes.isEmpty
            ? const <String>[]
            : <String>[notes];
        updatePayload['providerQualityEvaluation'] =
            Map<String, dynamic>.from(evaluation)..addAll({
              'status': 'emitida',
              'evidenceUrls': [...existingEvidence, ...urls],
              'evidenceCount': existingEvidence.length + urls.length,
              'incidentNotes': incidentNotes,
              'incidentCount': incidentNotes.length,
              'closureSummary': notes.isEmpty
                  ? evaluation['closureSummary']
                  : notes,
              'supervisorOrderCode': supervisorOrderCode,
              'updatedAt': FieldValue.serverTimestamp(),
            });
        updatePayload['providerQualityEvaluationStatus'] = 'emitida';
      } else {
        final technicalSheet =
            resolveTechnicalSurveySheet(requestData) ??
            buildInitialTechnicalSurveySheet(
              city: requestData['city']?.toString(),
              address: requestData['operationAddress']?.toString(),
              serviceCategory: requestData['serviceInterest']?.toString(),
              urgency: requestData['serviceUrgency']?.toString(),
            );
        final existingEvidence =
            (technicalSheet['photoEvidenceUrls'] as List?)
                ?.map((item) => item.toString())
                .toList() ??
            <String>[];
        updatePayload['technicalSurveySheet'] =
            Map<String, dynamic>.from(technicalSheet)..addAll({
              'status': 'emitida',
              'photoEvidenceUrls': [...existingEvidence, ...urls],
              'photoEvidenceCount': existingEvidence.length + urls.length,
              'recommendations': notes.isEmpty
                  ? technicalSheet['recommendations']
                  : notes,
              'supervisorOrderCode': supervisorOrderCode,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }

      await FirebaseFirestore.instance
          .collection('solicitudes')
          .doc(widget.solicitudId)
          .update(updatePayload);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.esActaFinal
                  ? 'Acta final guardada y sincronizada con la evaluación.'
                  : 'Acta inicial guardada y sincronizada con la ficha técnica.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      requiredRole: UserRole.supervisor,
      child: _SupervisorActaContent(
        formKey: _formKey,
        observacionesController: _observacionesController,
        evidencias: _evidencias,
        widget: widget,
        onGuardarActa: _guardarActa,
        onCaptureEvidence: _captureEvidence,
        onPickEvidenceFromGallery: _pickEvidenceFromGallery,
        onPickEvidenceFiles: _pickEvidenceFiles,
        onCaptureVisitLocation: _captureVisitLocation,
        onRemoveEvidence: (index) {
          setState(() {
            _evidencias.removeAt(index);
          });
        },
        condicionesVerificadas: _condicionesVerificadas,
        onCondicionesChanged: (value) {
          setState(() {
            _condicionesVerificadas = value;
          });
        },
        cumplimientoServicio: _cumplimientoServicio,
        visitLocation: _visitLocation,
        capturingLocation: _capturingLocation,
        onCumplimientoChanged: (value) {
          setState(() {
            _cumplimientoServicio = value;
          });
        },
        loading: _loading,
      ),
    );
  }
}

String? _sanitizeStorageSegment(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
}

class _SupervisorActaContent extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController observacionesController;
  final List<_SelectedEvidence> evidencias;
  final SupervisorActaPage widget;
  final Future<void> Function()? onGuardarActa;
  final Future<void> Function()? onCaptureEvidence;
  final Future<void> Function()? onPickEvidenceFromGallery;
  final Future<void> Function()? onPickEvidenceFiles;
  final Future<void> Function()? onCaptureVisitLocation;
  final ValueChanged<int>? onRemoveEvidence;
  final bool condicionesVerificadas;
  final ValueChanged<bool> onCondicionesChanged;
  final bool cumplimientoServicio;
  final Map<String, dynamic>? visitLocation;
  final bool capturingLocation;
  final ValueChanged<bool> onCumplimientoChanged;
  final bool loading;

  const _SupervisorActaContent({
    required this.formKey,
    required this.observacionesController,
    required this.evidencias,
    required this.widget,
    this.onGuardarActa,
    this.onCaptureEvidence,
    this.onPickEvidenceFromGallery,
    this.onPickEvidenceFiles,
    this.onCaptureVisitLocation,
    this.onRemoveEvidence,
    required this.condicionesVerificadas,
    required this.onCondicionesChanged,
    required this.cumplimientoServicio,
    required this.visitLocation,
    required this.capturingLocation,
    required this.onCumplimientoChanged,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.esActaFinal ? 'Acta Final' : 'Acta Inicial'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('solicitudes')
                    .doc(widget.solicitudId)
                    .snapshots(),
                builder: (context, snapshot) {
                  final orderCode =
                      snapshot.data?.data()?['supervisorOrderCode']?.toString();
                  if (orderCode == null || orderCode.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6FAF7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD6E3DA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tag_outlined, color: Color(0xFF0C4F31)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Orden de supervision',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                orderCode,
                                style: const TextStyle(
                                  color: Color(0xFF0C4F31),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Copiar numero de orden',
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: orderCode),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Numero de orden copiado.'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.copy_outlined),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Text(
                widget.esActaFinal
                    ? 'Sube evidencia y completa el acta final. Esta información alimentará la evaluación de calidad del proveedor.'
                    : 'Sube evidencia y completa el acta inicial. Esta información alimentará la ficha técnica previa a cotización.',
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6FAF7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD6E3DA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Georreferencia de visita',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      visitLocation == null
                          ? 'Aún no registras la ubicación de la visita.'
                          : 'Lat: ${visitLocation!['latitude']}\nLng: ${visitLocation!['longitude']}\nPrecisión: ${visitLocation!['accuracy']} m',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: loading || capturingLocation
                          ? null
                          : onCaptureVisitLocation,
                      icon: capturingLocation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location_outlined),
                      label: Text(
                        visitLocation == null
                            ? 'Registrar GPS'
                            : 'Actualizar GPS',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: loading ? null : onCaptureEvidence,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Tomar foto'),
                  ),
                  OutlinedButton.icon(
                    onPressed: loading ? null : onPickEvidenceFromGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galería'),
                  ),
                  OutlinedButton.icon(
                    onPressed: loading ? null : onPickEvidenceFiles,
                    icon: const Icon(Icons.attach_file_outlined),
                    label: const Text('Archivos'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (evidencias.isEmpty)
                const Text(
                  'Aún no has cargado evidencia para esta visita.',
                  style: TextStyle(color: Colors.black54),
                )
              else
                _LocalEvidencePreviewGrid(
                  evidencias: evidencias,
                  loading: loading,
                  onRemoveEvidence: onRemoveEvidence,
                ),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: widget.esActaFinal
                    ? cumplimientoServicio
                    : condicionesVerificadas,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  widget.esActaFinal
                      ? 'Se verificó cumplimiento del servicio'
                      : 'Se verificaron condiciones iniciales del punto',
                ),
                onChanged: loading
                    ? null
                    : (value) {
                        final resolved = value ?? false;
                        if (widget.esActaFinal) {
                          onCumplimientoChanged(resolved);
                        } else {
                          onCondicionesChanged(resolved);
                        }
                      },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: observacionesController,
                decoration: InputDecoration(
                  labelText: widget.esActaFinal
                      ? 'Observaciones finales'
                      : 'Observaciones',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese observaciones' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(loading ? 'Guardando...' : 'Guardar acta'),
                onPressed: loading ? null : onGuardarActa,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedEvidence {
  final String name;
  final String? path;
  final Uint8List? bytes;
  final String? extension;

  const _SelectedEvidence({
    required this.name,
    required this.path,
    required this.bytes,
    required this.extension,
  });
}

class _LocalEvidencePreviewGrid extends StatelessWidget {
  final List<_SelectedEvidence> evidencias;
  final bool loading;
  final ValueChanged<int>? onRemoveEvidence;

  const _LocalEvidencePreviewGrid({
    required this.evidencias,
    required this.loading,
    required this.onRemoveEvidence,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: evidencias.asMap().entries.map((entry) {
        return _LocalEvidenceTile(
          evidence: entry.value,
          enabled: !loading,
          onRemove: () => onRemoveEvidence?.call(entry.key),
        );
      }).toList(),
    );
  }
}

class _LocalEvidenceTile extends StatelessWidget {
  final _SelectedEvidence evidence;
  final bool enabled;
  final VoidCallback onRemove;

  const _LocalEvidenceTile({
    required this.evidence,
    required this.enabled,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final imageLike = _isImageFile(evidence.extension);
    final preview = _buildPreview(imageLike);

    return SizedBox(
      width: 112,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 112,
                  height: 112,
                  color: const Color(0xFFF3F6F4),
                  child: preview,
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: enabled ? onRemove : null,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            evidence.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(bool imageLike) {
    if (!imageLike) {
      return const Center(
        child: Icon(Icons.insert_drive_file_outlined, color: Colors.black45, size: 30),
      );
    }
    if (evidence.bytes != null) {
      return Image.memory(evidence.bytes!, fit: BoxFit.cover);
    }
    if (evidence.path != null && evidence.path!.isNotEmpty) {
      return Image.file(File(evidence.path!), fit: BoxFit.cover);
    }
    return const Center(
      child: Icon(Icons.broken_image_outlined, color: Colors.black45, size: 30),
    );
  }

  bool _isImageFile(String? extension) {
    final normalized = extension?.toLowerCase();
    return normalized == 'jpg' ||
        normalized == 'jpeg' ||
        normalized == 'png' ||
        normalized == 'webp';
  }
}
