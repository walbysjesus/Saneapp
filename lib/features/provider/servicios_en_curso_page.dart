import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/commercial_timeline_service.dart';
import '../../services/storage_service.dart';
import '../supervision/supervision_artifacts.dart';
import 'provider_access_guard.dart';

class ServiciosEnCursoPage extends StatefulWidget {
  const ServiciosEnCursoPage({super.key});

  @override
  State<ServiciosEnCursoPage> createState() => _ServiciosEnCursoPageState();
}

class _ServiciosEnCursoPageState extends State<ServiciosEnCursoPage> {
  final Set<String> _uploadingRequests = <String>{};

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No autenticado.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Servicios en curso')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('solicitudes')
            .where('selectedProveedorId', isEqualTo: user.uid)
            .where('status', whereIn: ['pago_confirmado', 'en_ejecucion'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ProviderOfflineView(
              title: 'No fue posible cargar servicios en curso',
              message:
                  'La conexión con Firestore no está disponible. Cuando se restablezca podrás seguir el estado operativo.',
              onRetry: () async {
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const ServiciosEnCursoPage(),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                );
              },
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No tienes servicios en curso.'));
          }
          final servicios = snapshot.data!.docs;
          return ListView.separated(
            itemCount: servicios.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final data = servicios[index].data() as Map<String, dynamic>;
              final docId = servicios[index].id;
              final status = data['status'] ?? '';
              final technicalSurveySheet = resolveTechnicalSurveySheet(data);
              final providerQualityEvaluation =
                  resolveProviderQualityEvaluation(data);
              final executionEvidence =
                  (data['providerExecutionEvidence'] as List?) ?? const [];
              final closeoutPackage =
                  data['providerCloseoutPackage'] is Map<String, dynamic>
                  ? data['providerCloseoutPackage'] as Map<String, dynamic>
                  : data['providerCloseoutPackage'] is Map
                  ? Map<String, dynamic>.from(
                      data['providerCloseoutPackage'] as Map,
                    )
                  : null;
              final uploading = _uploadingRequests.contains(docId);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.work),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              data['titulo'] ?? 'Servicio sin tÃ­tulo',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Estado: $status'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ExecutionPill(
                            label:
                                'Evidencias proveedor: ${executionEvidence.length}',
                          ),
                          _ExecutionPill(
                            label: 'Chat / custodia / cierre dentro de SaneApp',
                          ),
                        ],
                      ),
                      if (technicalSurveySheet != null) ...[
                        const SizedBox(height: 14),
                        TechnicalSurveySheetCard(
                          sheet: technicalSurveySheet,
                          providerFacing: true,
                        ),
                      ],
                      if (providerQualityEvaluation != null) ...[
                        const SizedBox(height: 14),
                        ProviderQualityEvaluationCard(
                          evaluation: providerQualityEvaluation,
                          providerFacing: true,
                        ),
                      ],
                      if (resolveSupervisorActa(data, finalActa: false) !=
                              null ||
                          resolveSupervisorActa(data, finalActa: true) !=
                              null ||
                          resolveSupervisorVisitLocation(data) != null ||
                          resolveSupervisionLogEntries(data).isNotEmpty ||
                          resolveSupervisorEvidenceUrls(data).isNotEmpty) ...[
                        const SizedBox(height: 14),
                        SupervisorSupportCard(
                          requestData: data,
                          providerFacing: true,
                        ),
                      ],
                      const SizedBox(height: 14),
                      if (closeoutPackage != null) ...[
                        _CloseoutPackageSummaryCard(closeoutPackage),
                        const SizedBox(height: 14),
                      ],
                      _ExecutionChecklistCard(
                        requestData: data,
                        evidenceCount: executionEvidence.length,
                        closeoutReady: closeoutPackage != null,
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: uploading
                                ? null
                                : () => _uploadExecutionEvidence(
                                    requestId: docId,
                                    requestTitle:
                                        data['titulo']?.toString() ??
                                        'Servicio',
                                  ),
                            icon: uploading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.upload_file_outlined),
                            label: Text(
                              uploading
                                  ? 'Subiendo evidencia...'
                                  : 'Subir evidencia',
                            ),
                          ),
                          if (status == 'en_ejecucion')
                            OutlinedButton.icon(
                              onPressed: () => _openCloseoutSheet(
                                requestId: docId,
                                requestTitle:
                                    data['titulo']?.toString() ?? 'Servicio',
                                currentPackage: closeoutPackage,
                              ),
                              icon: const Icon(
                                Icons.assignment_turned_in_outlined,
                              ),
                              label: Text(
                                closeoutPackage == null
                                    ? 'Preparar cierre'
                                    : 'Actualizar cierre',
                              ),
                            ),
                          if (status == 'pago_confirmado')
                            ElevatedButton(
                              child: const Text('Iniciar servicio'),
                              onPressed: () async {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) return;
                                final canOperate =
                                    await ensureProviderCanOperate(context);
                                if (!canOperate) {
                                  return;
                                }
                                await FirebaseFirestore.instance
                                    .collection('solicitudes')
                                    .doc(docId)
                                    .update({'status': 'en_ejecucion'});
                              },
                            ),
                          if (status == 'en_ejecucion')
                            ElevatedButton(
                              child: const Text('Marcar finalizado'),
                              onPressed: () async {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) return;
                                final canOperate =
                                    await ensureProviderCanOperate(context);
                                if (!canOperate) {
                                  return;
                                }
                                if (executionEvidence.isEmpty) {
                                  if (!mounted) {
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Adjunta al menos una evidencia antes de marcar el servicio como finalizado.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (closeoutPackage == null) {
                                  if (!mounted) {
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Prepara el paquete de cierre antes de marcar el servicio como finalizado.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                await FirebaseFirestore.instance
                                    .collection('solicitudes')
                                    .doc(docId)
                                    .update({
                                      'status':
                                          'finalizada_pendiente_confirmacion',
                                      'providerCloseoutChecklistCompleted':
                                          true,
                                      'providerCloseoutAt':
                                          FieldValue.serverTimestamp(),
                                    });
                                await CommercialTimelineService.recordEvent(
                                  requestId: docId,
                                  eventType: 'provider_execution_closed',
                                  title: 'Proveedor marcó cierre de ejecución',
                                  description:
                                      'El proveedor dejó la ejecución lista para confirmación con evidencias dentro del expediente.',
                                  actorId: user.uid,
                                  actorRole: 'proveedor',
                                );
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _uploadExecutionEvidence({
    required String requestId,
    required String requestTitle,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (!mounted || result == null || result.files.single.path == null) {
      return;
    }

    setState(() => _uploadingRequests.add(requestId));
    try {
      final file = File(result.files.single.path!);
      final url = await StorageService.uploadProviderDocument(file, user.uid);
      if (url == null || url.startsWith('ERROR:')) {
        throw Exception(url ?? 'No se pudo subir la evidencia.');
      }

      await FirebaseFirestore.instance
          .collection('solicitudes')
          .doc(requestId)
          .set({
            'providerExecutionEvidence': FieldValue.arrayUnion([
              {
                'url': url,
                'fileName': result.files.single.name,
                'uploadedBy': user.uid,
                'uploadedAt': FieldValue.serverTimestamp(),
              },
            ]),
            'providerLastEvidenceAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      await CommercialTimelineService.recordEvent(
        requestId: requestId,
        eventType: 'provider_execution_evidence_uploaded',
        title: 'Proveedor subió evidencia de ejecución',
        description:
            'Se cargó evidencia operativa del servicio dentro del expediente comercial.',
        actorId: user.uid,
        actorRole: 'proveedor',
        metadata: {
          'fileName': result.files.single.name,
          'requestTitle': requestTitle,
        },
      );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evidencia cargada al expediente del servicio.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo subir la evidencia: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _uploadingRequests.remove(requestId));
      }
    }
  }

  Future<void> _openCloseoutSheet({
    required String requestId,
    required String requestTitle,
    Map<String, dynamic>? currentPackage,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final actaController = TextEditingController(
      text: currentPackage?['actaSummary']?.toString() ?? '',
    );
    final deliverablesController = TextEditingController(
      text: currentPackage?['deliveredItems']?.toString() ?? '',
    );
    final incidentsController = TextEditingController(
      text: currentPackage?['incidents']?.toString() ?? '',
    );
    final readinessController = TextEditingController(
      text: currentPackage?['clientReadySummary']?.toString() ?? '',
    );

    try {
      final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Paquete de cierre proveedor',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    requestTitle,
                    style: const TextStyle(color: Color(0xFF68766F)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: actaController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Resumen de acta o cierre técnico',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: deliverablesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Entregables realizados',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: incidentsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Incidencias o novedades',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: readinessController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Estado para confirmación del cliente',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final actaSummary = actaController.text.trim();
                        final deliveredItems = deliverablesController.text
                            .trim();
                        final incidents = incidentsController.text.trim();
                        final clientReadySummary = readinessController.text
                            .trim();
                        if (actaSummary.isEmpty ||
                            deliveredItems.isEmpty ||
                            clientReadySummary.isEmpty) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Completa acta, entregables y estado para confirmación.',
                              ),
                            ),
                          );
                          return;
                        }

                        await FirebaseFirestore.instance
                            .collection('solicitudes')
                            .doc(requestId)
                            .set({
                              'providerCloseoutPackage': {
                                'actaSummary': actaSummary,
                                'deliveredItems': deliveredItems,
                                'incidents': incidents,
                                'clientReadySummary': clientReadySummary,
                                'preparedBy': user.uid,
                                'preparedAt': FieldValue.serverTimestamp(),
                              },
                            }, SetOptions(merge: true));

                        await CommercialTimelineService.recordEvent(
                          requestId: requestId,
                          eventType: 'provider_closeout_package_prepared',
                          title: 'Proveedor preparó paquete de cierre',
                          description:
                              'Se dejó el acta, entregables y estado final del servicio dentro del expediente comercial.',
                          actorId: user.uid,
                          actorRole: 'proveedor',
                          metadata: {
                            'requestTitle': requestTitle,
                            'hasIncidents': incidents.isNotEmpty,
                          },
                        );

                        if (!sheetContext.mounted) {
                          return;
                        }
                        Navigator.of(sheetContext).pop(true);
                      },
                      child: const Text('Guardar paquete de cierre'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (!mounted || saved != true) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paquete de cierre actualizado en el expediente.'),
        ),
      );
    } finally {
      actaController.dispose();
      deliverablesController.dispose();
      incidentsController.dispose();
      readinessController.dispose();
    }
  }
}

class _ExecutionChecklistCard extends StatelessWidget {
  final Map<String, dynamic> requestData;
  final int evidenceCount;
  final bool closeoutReady;

  const _ExecutionChecklistCard({
    required this.requestData,
    required this.evidenceCount,
    required this.closeoutReady,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _ExecutionChecklistItem(
        'Evidencia de ejecución cargada',
        evidenceCount > 0,
      ),
      _ExecutionChecklistItem(
        'Ficha o soporte supervisor disponible',
        resolveSupervisorEvidenceUrls(requestData).isNotEmpty ||
            resolveSupervisionLogEntries(requestData).isNotEmpty,
      ),
      _ExecutionChecklistItem(
        'Pago protegido en SaneApp',
        (requestData['paymentStatus']?.toString() ?? '').isNotEmpty,
      ),
      _ExecutionChecklistItem('Paquete de cierre preparado', closeoutReady),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE7DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Checklist de cierre proveedor',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    item.done
                        ? Icons.check_circle_outline
                        : Icons.radio_button_unchecked,
                    color: item.done
                        ? const Color(0xFF1E7A4B)
                        : const Color(0xFF8A9891),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item.label)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExecutionChecklistItem {
  final String label;
  final bool done;

  const _ExecutionChecklistItem(this.label, this.done);
}

class _CloseoutPackageSummaryCard extends StatelessWidget {
  final Map<String, dynamic> closeoutPackage;

  const _CloseoutPackageSummaryCard(this.closeoutPackage);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE7DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paquete de cierre listo',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _CloseoutLine(
            'Acta',
            closeoutPackage['actaSummary']?.toString() ?? 'Sin resumen',
          ),
          _CloseoutLine(
            'Entregables',
            closeoutPackage['deliveredItems']?.toString() ?? 'Sin detalle',
          ),
          _CloseoutLine(
            'Incidencias',
            closeoutPackage['incidents']?.toString().trim().isNotEmpty == true
                ? closeoutPackage['incidents'].toString()
                : 'Sin novedades reportadas',
          ),
          _CloseoutLine(
            'Listo para cliente',
            closeoutPackage['clientReadySummary']?.toString() ?? 'Pendiente',
          ),
        ],
      ),
    );
  }
}

class _CloseoutLine extends StatelessWidget {
  final String label;
  final String value;

  const _CloseoutLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.copyWith(height: 1.35),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _ExecutionPill extends StatelessWidget {
  final String label;

  const _ExecutionPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6F2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF51635A),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
