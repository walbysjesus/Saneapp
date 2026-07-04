import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../supervision/supervision_artifacts.dart';
import 'supervisor_acta_page.dart';

class SupervisorSupervisionWorkbenchPage extends StatefulWidget {
  final String solicitudId;

  const SupervisorSupervisionWorkbenchPage({
    super.key,
    required this.solicitudId,
  });

  @override
  State<SupervisorSupervisionWorkbenchPage> createState() =>
      _SupervisorSupervisionWorkbenchPageState();
}

class _SupervisorSupervisionWorkbenchPageState
    extends State<SupervisorSupervisionWorkbenchPage> {
  static const _brandGreen = Color(0xFF0C4F31);
  static const _alertColor = Color(0xFFC24E00);

  final _siteAccessController = TextEditingController();
  final _residueProfileController = TextEditingController();
  final _operationalRisksController = TextEditingController();
  final _requiredEquipmentController = TextEditingController();
  final _recommendationsController = TextEditingController();
  final _providerGuidanceController = TextEditingController();
  final _fieldLogController = TextEditingController();
  final _incidentNotesController = TextEditingController();
  final _improvementActionsController = TextEditingController();
  final _closureSummaryController = TextEditingController();

  bool _loading = true;
  bool _savingTechnicalSheet = false;
  bool _savingQualityEvaluation = false;
  bool _uploadingTechnicalEvidence = false;
  bool _uploadingQualityEvidence = false;
  double? _technicalUploadProgress;
  double? _qualityUploadProgress;

  Map<String, dynamic>? _requestData;
  Map<String, dynamic>? _technicalSurveySheet;
  Map<String, dynamic>? _providerQualityEvaluation;

  String _technicalSheetStatus = 'pendiente_levantamiento';
  String _qualityEvaluationStatus = 'pendiente';
  int _goodPracticesScore = 0;
  int _punctualityScore = 0;
  int _executionQualityScore = 0;
  int _communicationScore = 0;
  int _safetyComplianceScore = 0;
  int _environmentalHandlingScore = 0;
  int _documentationScore = 0;
  int _presentationScore = 0;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  @override
  void dispose() {
    _siteAccessController.dispose();
    _residueProfileController.dispose();
    _operationalRisksController.dispose();
    _requiredEquipmentController.dispose();
    _recommendationsController.dispose();
    _providerGuidanceController.dispose();
    _fieldLogController.dispose();
    _incidentNotesController.dispose();
    _improvementActionsController.dispose();
    _closureSummaryController.dispose();
    super.dispose();
  }

  Future<void> _loadRequest() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('solicitudes')
          .doc(widget.solicitudId)
          .get();
      final data = snapshot.data();
      if (data == null) {
        if (!mounted) {
          return;
        }
        Navigator.of(context).pop();
        return;
      }

      final technicalSheet = resolveTechnicalSurveySheet(data);
      final qualityEvaluation = resolveProviderQualityEvaluation(data);

      _requestData = data;
      _technicalSurveySheet = technicalSheet;
      _providerQualityEvaluation = qualityEvaluation;
      _technicalSheetStatus =
          technicalSheet?['status']?.toString() ?? 'pendiente_levantamiento';
      _qualityEvaluationStatus =
          qualityEvaluation?['status']?.toString() ?? 'pendiente';

      _siteAccessController.text =
          technicalSheet?['siteAccess']?.toString() ?? '';
      _residueProfileController.text =
          technicalSheet?['residueProfile']?.toString() ?? '';
      _operationalRisksController.text =
          technicalSheet?['operationalRisks']?.toString() ?? '';
      _requiredEquipmentController.text =
          technicalSheet?['requiredEquipment']?.toString() ?? '';
      _recommendationsController.text =
          technicalSheet?['recommendations']?.toString() ?? '';
      _providerGuidanceController.text =
          technicalSheet?['providerGuidance']?.toString() ?? '';
      _fieldLogController.text =
          ((data['supervisionLogEntries'] as List?)
              ?.map((item) => item.toString())
              .join('\n') ??
          '');

      _goodPracticesScore =
          (qualityEvaluation?['goodPracticesScore'] as num?)?.toInt() ?? 0;
      _punctualityScore =
          (qualityEvaluation?['punctualityScore'] as num?)?.toInt() ?? 0;
      _executionQualityScore =
          (qualityEvaluation?['executionQualityScore'] as num?)?.toInt() ?? 0;
      _communicationScore =
          (qualityEvaluation?['communicationScore'] as num?)?.toInt() ?? 0;
      _safetyComplianceScore =
          (qualityEvaluation?['safetyComplianceScore'] as num?)?.toInt() ?? 0;
      _environmentalHandlingScore =
          (qualityEvaluation?['environmentalHandlingScore'] as num?)?.toInt() ??
          0;
      _documentationScore =
          (qualityEvaluation?['documentationScore'] as num?)?.toInt() ?? 0;
      _presentationScore =
          (qualityEvaluation?['presentationScore'] as num?)?.toInt() ?? 0;
      _incidentNotesController.text =
          ((qualityEvaluation?['incidentNotes'] as List?)
              ?.map((item) => item.toString())
              .join('\n') ??
          '');
      _improvementActionsController.text =
          qualityEvaluation?['improvementActions']?.toString() ?? '';
      _closureSummaryController.text =
          qualityEvaluation?['closureSummary']?.toString() ?? '';
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      appBar: AppBar(
        title: const Text('Mesa de supervisión'),
        backgroundColor: _brandGreen,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requestData == null
          ? const Center(child: Text('No se encontró la solicitud.'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _HeaderCard(
                  title: _requestData?['titulo']?.toString() ?? 'Solicitud',
                  city: _requestData?['city']?.toString() ?? 'Sin ciudad',
                  journey: _requestData?['supervisionJourney']?.toString(),
                ),
                const SizedBox(height: 16),
                _QuickActionsCard(
                  onInitialActa: _technicalSurveySheet == null
                      ? null
                      : () {
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (_) => SupervisorActaPage(
                                    solicitudId: widget.solicitudId,
                                    esActaFinal: false,
                                  ),
                                ),
                              )
                              .then((_) => _loadRequest());
                        },
                  onFinalActa: _providerQualityEvaluation == null
                      ? null
                      : () {
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (_) => SupervisorActaPage(
                                    solicitudId: widget.solicitudId,
                                    esActaFinal: true,
                                  ),
                                ),
                              )
                              .then((_) => _loadRequest());
                        },
                ),
                if (_technicalSurveySheet != null) ...[
                  const SizedBox(height: 16),
                  _EditorSectionCard(
                    title: 'Ficha técnica previa a cotización',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _technicalSheetStatus,
                          decoration: _inputDecoration('Estado de ficha'),
                          items: const [
                            DropdownMenuItem(
                              value: 'pendiente_levantamiento',
                              child: Text('Pendiente de visita'),
                            ),
                            DropdownMenuItem(
                              value: 'en_levantamiento',
                              child: Text('Levantamiento en curso'),
                            ),
                            DropdownMenuItem(
                              value: 'emitida',
                              child: Text('Ficha emitida'),
                            ),
                            DropdownMenuItem(
                              value: 'compartida_con_proveedor',
                              child: Text('Compartida con proveedor'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _technicalSheetStatus =
                                  value ?? 'pendiente_levantamiento';
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _siteAccessController,
                          decoration: _inputDecoration('Accesos y maniobras'),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _residueProfileController,
                          decoration: _inputDecoration('Perfil de residuos'),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _operationalRisksController,
                          decoration: _inputDecoration('Riesgos operativos'),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _requiredEquipmentController,
                          decoration: _inputDecoration('Equipos requeridos'),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _recommendationsController,
                          decoration: _inputDecoration(
                            'Recomendaciones técnicas',
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _providerGuidanceController,
                          decoration: _inputDecoration(
                            'Guía visible para proveedor',
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _fieldLogController,
                          decoration: _inputDecoration(
                            'Bitácora de campo (una novedad por línea)',
                          ),
                          maxLines: 5,
                        ),
                        const SizedBox(height: 14),
                        _EvidencePanel(
                          title: 'Evidencia de la ficha',
                          urls:
                              (_technicalSurveySheet?['photoEvidenceUrls']
                                      as List?)
                                  ?.map((item) => item.toString())
                                  .toList() ??
                              const [],
                          uploading: _uploadingTechnicalEvidence,
                          progress: _technicalUploadProgress,
                          onAdd: () => _pickAndUploadEvidence(technical: true),
                          onReplace: () => _pickAndUploadEvidence(
                            technical: true,
                            replaceExisting: true,
                          ),
                          onRemove: (index) =>
                              _removeEvidence(technical: true, index: index),
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: _savingTechnicalSheet
                              ? null
                              : _saveTechnicalSheet,
                          style: FilledButton.styleFrom(
                            backgroundColor: _brandGreen,
                          ),
                          icon: _savingTechnicalSheet
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: const Text('Guardar ficha técnica'),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_providerQualityEvaluation != null) ...[
                  const SizedBox(height: 16),
                  _EditorSectionCard(
                    title: 'Evaluación de calidad del proveedor',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _qualityEvaluationStatus,
                          decoration: _inputDecoration('Estado de evaluación'),
                          items: const [
                            DropdownMenuItem(
                              value: 'pendiente',
                              child: Text('Pendiente'),
                            ),
                            DropdownMenuItem(
                              value: 'en_revision',
                              child: Text('En revisión'),
                            ),
                            DropdownMenuItem(
                              value: 'emitida',
                              child: Text('Evaluación emitida'),
                            ),
                            DropdownMenuItem(
                              value: 'socializada',
                              child: Text('Socializada'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _qualityEvaluationStatus = value ?? 'pendiente';
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _ScoreField(
                              label: 'Buenas prácticas',
                              value: _goodPracticesScore,
                              onChanged: (value) {
                                setState(() {
                                  _goodPracticesScore = value;
                                });
                              },
                            ),
                            _ScoreField(
                              label: 'Puntualidad',
                              value: _punctualityScore,
                              onChanged: (value) {
                                setState(() {
                                  _punctualityScore = value;
                                });
                              },
                            ),
                            _ScoreField(
                              label: 'Calidad técnica',
                              value: _executionQualityScore,
                              onChanged: (value) {
                                setState(() {
                                  _executionQualityScore = value;
                                });
                              },
                            ),
                            _ScoreField(
                              label: 'Comunicación',
                              value: _communicationScore,
                              onChanged: (value) {
                                setState(() {
                                  _communicationScore = value;
                                });
                              },
                            ),
                            _ScoreField(
                              label: 'Seguridad y EPP',
                              value: _safetyComplianceScore,
                              onChanged: (value) {
                                setState(() {
                                  _safetyComplianceScore = value;
                                });
                              },
                            ),
                            _ScoreField(
                              label: 'Manejo ambiental',
                              value: _environmentalHandlingScore,
                              onChanged: (value) {
                                setState(() {
                                  _environmentalHandlingScore = value;
                                });
                              },
                            ),
                            _ScoreField(
                              label: 'Documentación',
                              value: _documentationScore,
                              onChanged: (value) {
                                setState(() {
                                  _documentationScore = value;
                                });
                              },
                            ),
                            _ScoreField(
                              label: 'Presentación cuadrilla',
                              value: _presentationScore,
                              onChanged: (value) {
                                setState(() {
                                  _presentationScore = value;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _EvaluationSummaryCard(
                          overallScore: _overallProviderScore,
                          concept: _providerConcept,
                          recommendation: _providerRecommendation,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _incidentNotesController,
                          decoration: _inputDecoration(
                            'Incidencias u observaciones (una por línea)',
                          ),
                          maxLines: 4,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _improvementActionsController,
                          decoration: _inputDecoration('Acciones de mejora'),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _closureSummaryController,
                          decoration: _inputDecoration('Resumen de cierre'),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 14),
                        _EvidencePanel(
                          title: 'Evidencia de calidad y ejecución',
                          urls:
                              (_providerQualityEvaluation?['evidenceUrls']
                                      as List?)
                                  ?.map((item) => item.toString())
                                  .toList() ??
                              const [],
                          uploading: _uploadingQualityEvidence,
                          progress: _qualityUploadProgress,
                          onAdd: () => _pickAndUploadEvidence(technical: false),
                          onReplace: () => _pickAndUploadEvidence(
                            technical: false,
                            replaceExisting: true,
                          ),
                          onRemove: (index) =>
                              _removeEvidence(technical: false, index: index),
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: _savingQualityEvaluation
                              ? null
                              : _saveQualityEvaluation,
                          style: FilledButton.styleFrom(
                            backgroundColor: _alertColor,
                          ),
                          icon: _savingQualityEvaluation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.verified_outlined),
                          label: const Text('Guardar evaluación'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD6E3DA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD6E3DA)),
      ),
    );
  }

  Future<void> _saveTechnicalSheet() async {
    final current = _technicalSurveySheet;
    if (current == null) {
      return;
    }
    final supervisorOrderCode = _requestData?['supervisorOrderCode']
        ?.toString();
    final preferredProviderId =
        _requestData?['preferredProviderId']?.toString() ?? '';
    final preferredProviderName =
        _requestData?['preferredProviderName']?.toString() ?? '';
    final preferredProviderServiceId =
        _requestData?['preferredProviderServiceId']?.toString() ?? '';
    final preferredProviderServiceTitle =
        _requestData?['preferredProviderServiceTitle']?.toString() ?? '';
    final preferredProviderServicePriceType =
        _requestData?['preferredProviderServicePriceType']?.toString() ?? '';
    final hasDirectedProvider = preferredProviderId.isNotEmpty;
    final effectiveStatus =
        hasDirectedProvider && _technicalSheetStatus == 'emitida'
        ? 'compartida_con_proveedor'
        : _technicalSheetStatus;
    final rawCommercialRouting = _requestData?['commercialRouting'];
    final commercialRouting = rawCommercialRouting is Map
        ? Map<String, dynamic>.from(rawCommercialRouting)
        : <String, dynamic>{};

    setState(() {
      _savingTechnicalSheet = true;
    });

    final updated = Map<String, dynamic>.from(current)
      ..addAll({
        'status': effectiveStatus,
        'siteAccess': _siteAccessController.text.trim(),
        'residueProfile': _residueProfileController.text.trim(),
        'operationalRisks': _operationalRisksController.text.trim(),
        'requiredEquipment': _requiredEquipmentController.text.trim(),
        'recommendations': _recommendationsController.text.trim(),
        'providerGuidance': _providerGuidanceController.text.trim(),
        'fieldLogEntries': _fieldLogEntries,
        'supervisorOrderCode': supervisorOrderCode,
        if (hasDirectedProvider)
          'targetProvider': {
            'providerId': preferredProviderId,
            'providerName': preferredProviderName,
            'serviceId': preferredProviderServiceId,
            'serviceTitle': preferredProviderServiceTitle,
            'priceType': preferredProviderServicePriceType,
          },
        'updatedAt': FieldValue.serverTimestamp(),
      });

    if (hasDirectedProvider) {
      commercialRouting['preferredProviderId'] = preferredProviderId;
      commercialRouting['preferredProviderName'] = preferredProviderName;
      commercialRouting['preferredProviderServiceId'] =
          preferredProviderServiceId;
      commercialRouting['preferredProviderServiceTitle'] =
          preferredProviderServiceTitle;
      commercialRouting['preferredProviderServicePriceType'] =
          preferredProviderServicePriceType;
      commercialRouting['technicalSheetStatus'] = effectiveStatus;
      commercialRouting['technicalSheetReadyForQuote'] =
          effectiveStatus == 'compartida_con_proveedor' ||
          effectiveStatus == 'emitida';
    }

    try {
      await FirebaseFirestore.instance
          .collection('solicitudes')
          .doc(widget.solicitudId)
          .set({
            'technicalSurveySheet': updated,
            'supervisionLogEntries': _fieldLogEntries,
            'commercialRouting': commercialRouting.isEmpty
                ? null
                : commercialRouting,
            'commercialFlowStage': hasDirectedProvider
                ? 'technical_sheet_ready_for_provider_quote'
                : 'technical_sheet_ready_for_generator_review',
            'commercialFlowUpdatedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      _technicalSurveySheet = updated;
      _technicalSheetStatus = effectiveStatus;
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ficha técnica guardada.')));
    } finally {
      if (mounted) {
        setState(() {
          _savingTechnicalSheet = false;
        });
      }
    }
  }

  Future<void> _saveQualityEvaluation() async {
    final current = _providerQualityEvaluation;
    if (current == null) {
      return;
    }
    final supervisorOrderCode = _requestData?['supervisorOrderCode']
        ?.toString();

    setState(() {
      _savingQualityEvaluation = true;
    });

    final incidentNotes = _incidentNotesController.text
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    final updated = Map<String, dynamic>.from(current)
      ..addAll({
        'status': _qualityEvaluationStatus,
        'goodPracticesScore': _goodPracticesScore == 0
            ? null
            : _goodPracticesScore,
        'punctualityScore': _punctualityScore == 0 ? null : _punctualityScore,
        'executionQualityScore': _executionQualityScore == 0
            ? null
            : _executionQualityScore,
        'communicationScore': _communicationScore == 0
            ? null
            : _communicationScore,
        'safetyComplianceScore': _safetyComplianceScore == 0
            ? null
            : _safetyComplianceScore,
        'environmentalHandlingScore': _environmentalHandlingScore == 0
            ? null
            : _environmentalHandlingScore,
        'documentationScore': _documentationScore == 0
            ? null
            : _documentationScore,
        'presentationScore': _presentationScore == 0
            ? null
            : _presentationScore,
        'overallScore': _overallProviderScore,
        'concept': _providerConcept,
        'recommendation': _providerRecommendation,
        'incidentCount': incidentNotes.length,
        'incidentNotes': incidentNotes,
        'improvementActions': _improvementActionsController.text.trim(),
        'closureSummary': _closureSummaryController.text.trim(),
        'supervisorOrderCode': supervisorOrderCode,
        'updatedAt': FieldValue.serverTimestamp(),
      });

    try {
      await FirebaseFirestore.instance
          .collection('solicitudes')
          .doc(widget.solicitudId)
          .set({
            'providerQualityEvaluation': updated,
            'providerQualityEvaluationStatus': _qualityEvaluationStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      _providerQualityEvaluation = updated;
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evaluación de calidad guardada.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingQualityEvaluation = false;
        });
      }
    }
  }

  List<String> get _fieldLogEntries => _fieldLogController.text
      .split('\n')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  int get _overallProviderScore {
    final scores = [
      _goodPracticesScore,
      _punctualityScore,
      _executionQualityScore,
      _communicationScore,
      _safetyComplianceScore,
      _environmentalHandlingScore,
      _documentationScore,
      _presentationScore,
    ];
    final filled = scores.where((score) => score > 0).toList();
    if (filled.isEmpty) {
      return 0;
    }
    final total = filled.fold<int>(0, (sum, score) => sum + score);
    return ((total / (filled.length * 5)) * 100).round();
  }

  String get _providerConcept {
    final score = _overallProviderScore;
    if (score >= 90) {
      return 'Excelente';
    }
    if (score >= 75) {
      return 'Aceptable';
    }
    if (score >= 60) {
      return 'Condicionado';
    }
    return 'No conforme';
  }

  String get _providerRecommendation {
    switch (_providerConcept) {
      case 'Excelente':
        return 'Proveedor recomendado para nuevos servicios críticos.';
      case 'Aceptable':
        return 'Proveedor operativo con seguimiento normal.';
      case 'Condicionado':
        return 'Proveedor con observaciones; requiere plan de mejora y seguimiento.';
      default:
        return 'Proveedor no conforme; escalar revisión antes de nuevas asignaciones.';
    }
  }

  Future<void> _pickAndUploadEvidence({
    required bool technical,
    bool replaceExisting = false,
  }) async {
    final current = technical
        ? _technicalSurveySheet
        : _providerQualityEvaluation;
    if (current == null) {
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    final files = result?.files ?? const <PlatformFile>[];
    if (files.isEmpty) {
      return;
    }

    setState(() {
      if (technical) {
        _uploadingTechnicalEvidence = true;
        _technicalUploadProgress = 0;
      } else {
        _uploadingQualityEvidence = true;
        _qualityUploadProgress = 0;
      }
    });

    try {
      final uploadedUrls = <String>[];
      final totalFiles = files.length;
      final orderCode = _sanitizeStorageSegment(
        _requestData?['supervisorOrderCode']?.toString(),
      );
      final orderFolder = orderCode ?? 'sin-codigo';
      for (var index = 0; index < files.length; index++) {
        final file = files[index];
        final folder = technical ? 'technical_sheet' : 'quality_evaluation';
        final extension = file.extension ?? 'jpg';
        final ref = FirebaseStorage.instance.ref().child(
          'solicitudes/${widget.solicitudId}/ordenes_supervision/$orderFolder/supervision/$folder/${DateTime.now().millisecondsSinceEpoch}_$index.$extension',
        );
        final uploadTask = await _startUpload(
          ref: ref,
          path: file.path,
          bytes: file.bytes,
        );
        uploadTask.snapshotEvents.listen((snapshot) {
          if (!mounted) {
            return;
          }
          final totalBytes = snapshot.totalBytes;
          final currentProgress = totalBytes > 0
              ? snapshot.bytesTransferred / totalBytes
              : 0.0;
          final overall = (index + currentProgress) / totalFiles;
          setState(() {
            if (technical) {
              _technicalUploadProgress = overall;
            } else {
              _qualityUploadProgress = overall;
            }
          });
        });
        await uploadTask;
        uploadedUrls.add(await ref.getDownloadURL());
      }

      Object? rawExistingUrls;
      if (technical) {
        rawExistingUrls = _technicalSurveySheet?['photoEvidenceUrls'];
      } else {
        rawExistingUrls = _providerQualityEvaluation?['evidenceUrls'];
      }
      final existingUrls =
          (rawExistingUrls as List?)?.map((item) => item.toString()).toList() ??
          <String>[];
      final mergedUrls = replaceExisting
          ? uploadedUrls
          : [...existingUrls, ...uploadedUrls];

      if (technical) {
        final updated = Map<String, dynamic>.from(_technicalSurveySheet!)
          ..addAll({
            'status': _technicalSheetStatus == 'pendiente_levantamiento'
                ? 'en_levantamiento'
                : _technicalSheetStatus,
            'photoEvidenceUrls': mergedUrls,
            'photoEvidenceCount': mergedUrls.length,
            'supervisorOrderCode': _requestData?['supervisorOrderCode']
                ?.toString(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        await FirebaseFirestore.instance
            .collection('solicitudes')
            .doc(widget.solicitudId)
            .set({
              'technicalSurveySheet': updated,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
        _technicalSurveySheet = updated;
        _technicalSheetStatus =
            updated['status']?.toString() ?? _technicalSheetStatus;
      } else {
        final updated = Map<String, dynamic>.from(_providerQualityEvaluation!)
          ..addAll({
            'status': _qualityEvaluationStatus == 'pendiente'
                ? 'en_revision'
                : _qualityEvaluationStatus,
            'evidenceUrls': mergedUrls,
            'evidenceCount': mergedUrls.length,
            'supervisorOrderCode': _requestData?['supervisorOrderCode']
                ?.toString(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        await FirebaseFirestore.instance
            .collection('solicitudes')
            .doc(widget.solicitudId)
            .set({
              'providerQualityEvaluation': updated,
              'providerQualityEvaluationStatus': updated['status'],
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
        _providerQualityEvaluation = updated;
        _qualityEvaluationStatus =
            updated['status']?.toString() ?? _qualityEvaluationStatus;
      }

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            technical
                ? 'Evidencia de ficha técnica cargada.'
                : 'Evidencia de evaluación cargada.',
          ),
        ),
      );
      setState(() {});
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No fue posible cargar la evidencia seleccionada.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          if (technical) {
            _uploadingTechnicalEvidence = false;
            _technicalUploadProgress = null;
          } else {
            _uploadingQualityEvidence = false;
            _qualityUploadProgress = null;
          }
        });
      }
    }
  }

  Future<void> _removeEvidence({
    required bool technical,
    required int index,
  }) async {
    final current = technical
        ? _technicalSurveySheet
        : _providerQualityEvaluation;
    if (current == null) {
      return;
    }

    final key = technical ? 'photoEvidenceUrls' : 'evidenceUrls';
    final countKey = technical ? 'photoEvidenceCount' : 'evidenceCount';
    final currentUrls =
        (current[key] as List?)?.map((item) => item.toString()).toList() ??
        <String>[];
    if (index < 0 || index >= currentUrls.length) {
      return;
    }

    currentUrls.removeAt(index);
    final updated = Map<String, dynamic>.from(current)
      ..addAll({
        key: currentUrls,
        countKey: currentUrls.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });

    await FirebaseFirestore.instance
        .collection('solicitudes')
        .doc(widget.solicitudId)
        .set({
          technical ? 'technicalSurveySheet' : 'providerQualityEvaluation':
              updated,
          if (!technical)
            'providerQualityEvaluationStatus': _qualityEvaluationStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    if (!mounted) {
      return;
    }

    setState(() {
      if (technical) {
        _technicalSurveySheet = updated;
      } else {
        _providerQualityEvaluation = updated;
      }
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Evidencia eliminada.')));
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
}

String? _sanitizeStorageSegment(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
}

class _HeaderCard extends StatelessWidget {
  final String title;
  final String city;
  final String? journey;

  const _HeaderCard({
    required this.title,
    required this.city,
    required this.journey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0C4F31), Color(0xFF1E7A4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(label: city),
              _Tag(label: _mapJourney(journey)),
            ],
          ),
        ],
      ),
    );
  }

  static String _mapJourney(String? value) {
    switch (value) {
      case 'execution_traceability':
        return 'Ejecución y calidad';
      case 'prequote_diagnostic':
      default:
        return 'Preinspección técnica';
    }
  }
}

class _QuickActionsCard extends StatelessWidget {
  final VoidCallback? onInitialActa;
  final VoidCallback? onFinalActa;

  const _QuickActionsCard({this.onInitialActa, this.onFinalActa});

  @override
  Widget build(BuildContext context) {
    return _EditorSectionCard(
      title: 'Actas vinculadas',
      child: Row(
        children: [
          if (onInitialActa != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onInitialActa,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Acta inicial'),
              ),
            ),
          if (onInitialActa != null && onFinalActa != null)
            const SizedBox(width: 12),
          if (onFinalActa != null)
            Expanded(
              child: FilledButton.icon(
                onPressed: onFinalActa,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC24E00),
                ),
                icon: const Icon(Icons.assignment_turned_in_outlined),
                label: const Text('Acta final'),
              ),
            ),
        ],
      ),
    );
  }
}

class _EditorSectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _EditorSectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCE7DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _EvidencePanel extends StatelessWidget {
  final String title;
  final List<String> urls;
  final bool uploading;
  final double? progress;
  final VoidCallback onAdd;
  final VoidCallback onReplace;
  final ValueChanged<int> onRemove;

  const _EvidencePanel({
    required this.title,
    required this.urls,
    required this.uploading,
    required this.progress,
    required this.onAdd,
    required this.onReplace,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE7DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton.icon(
                onPressed: uploading ? null : onAdd,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Agregar'),
              ),
              TextButton.icon(
                onPressed: uploading ? null : onReplace,
                icon: const Icon(Icons.autorenew_outlined),
                label: const Text('Reemplazar'),
              ),
            ],
          ),
          if (uploading) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 6),
            Text(
              progress == null
                  ? 'Cargando evidencia...'
                  : 'Cargando ${(progress! * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.black54),
            ),
          ],
          if (urls.isEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Todavía no hay evidencias cargadas.',
              style: TextStyle(color: Colors.black54),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: urls.asMap().entries.map((entry) {
                return InputChip(
                  onPressed: () => _openUrl(entry.value),
                  label: Text('Evidencia ${entry.key + 1}'),
                  avatar: const Icon(Icons.attachment_outlined, size: 18),
                  onDeleted: uploading ? null : () => onRemove(entry.key),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

class _ScoreField extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _ScoreField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<int>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        items: const [
          DropdownMenuItem(value: 0, child: Text('Pendiente')),
          DropdownMenuItem(value: 1, child: Text('1/5')),
          DropdownMenuItem(value: 2, child: Text('2/5')),
          DropdownMenuItem(value: 3, child: Text('3/5')),
          DropdownMenuItem(value: 4, child: Text('4/5')),
          DropdownMenuItem(value: 5, child: Text('5/5')),
        ],
        onChanged: (selected) => onChanged(selected ?? 0),
      ),
    );
  }
}

class _EvaluationSummaryCard extends StatelessWidget {
  final int overallScore;
  final String concept;
  final String recommendation;

  const _EvaluationSummaryCard({
    required this.overallScore,
    required this.concept,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E3DA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de evaluación',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Resultado total: $overallScore/100',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text('Concepto: $concept'),
          const SizedBox(height: 4),
          Text(
            recommendation,
            style: const TextStyle(color: Colors.black54, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;

  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
