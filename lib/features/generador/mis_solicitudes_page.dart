import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'solicitud_detalle_page.dart';
import '../supervision/supervision_artifacts.dart';

class MisSolicitudesPage extends StatefulWidget {
  const MisSolicitudesPage({super.key});

  static const _brandGreen = Color(0xFF0C4F31);
  static const _brandGreenSoft = Color(0xFF1E7A4B);

  @override
  State<MisSolicitudesPage> createState() => _MisSolicitudesPageState();
}

class _MisSolicitudesPageState extends State<MisSolicitudesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No autenticado.')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      appBar: AppBar(
        title: const Text('Mis solicitudes'),
        backgroundColor: MisSolicitudesPage._brandGreen,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('solicitudes')
            .where('generadorId', isEqualTo: user.uid)
            .where('type', whereIn: ['normal', 'emergency'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) {
            return const _EmptyState();
          }

          final sorted = [...docs]
            ..sort((a, b) {
              final tsA = a.data()['createdAt'];
              final tsB = b.data()['createdAt'];
              final dateA = tsA is Timestamp
                  ? tsA.toDate()
                  : DateTime.fromMillisecondsSinceEpoch(0);
              final dateB = tsB is Timestamp
                  ? tsB.toDate()
                  : DateTime.fromMillisecondsSinceEpoch(0);
              return dateB.compareTo(dateA);
            });

          final filtered = sorted.where((doc) {
            final data = doc.data();
            final query = _searchQuery.trim().toLowerCase();
            if (query.isEmpty) {
              return true;
            }
            final orderCode = data['supervisorOrderCode']?.toString() ?? '';
            final title = data['titulo']?.toString() ?? '';
            return '$orderCode $title'.toLowerCase().contains(query);
          }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            children: [
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar por orden de supervision o titulo',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _SummaryStrip(documents: filtered),
              const SizedBox(height: 16),
              ...filtered.map(
                (doc) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _RequestCard(data: doc.data(), requestId: doc.id),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> documents;

  const _SummaryStrip({required this.documents});

  @override
  Widget build(BuildContext context) {
    final total = documents.length;
    final emergency = documents
        .where((doc) => doc.data()['type'] == 'emergency')
        .length;
    final supervised = documents
        .where((doc) => doc.data()['supervisorRequested'] == true)
        .length;
    final active = documents.where((doc) {
      final status = doc.data()['status']?.toString().toLowerCase() ?? '';
      return status.isEmpty ||
          status == 'pending' ||
          status == 'abierta' ||
          status == 'en_proceso';
    }).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCE7DF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              value: '$total',
              label: 'Publicadas',
              accentColor: MisSolicitudesPage._brandGreen,
            ),
          ),
          Expanded(
            child: _SummaryItem(
              value: '$active',
              label: 'Activas',
              accentColor: MisSolicitudesPage._brandGreenSoft,
            ),
          ),
          Expanded(
            child: _SummaryItem(
              value: '$emergency',
              label: 'Urgentes',
              accentColor: const Color(0xFFC24E00),
            ),
          ),
          Expanded(
            child: _SummaryItem(
              value: '$supervised',
              label: 'Supervisadas',
              accentColor: const Color(0xFF3B6EA5),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String value;
  final String label;
  final Color accentColor;

  const _SummaryItem({
    required this.value,
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String requestId;

  const _RequestCard({required this.data, required this.requestId});

  @override
  Widget build(BuildContext context) {
    final isEmergency = data['type'] == 'emergency';
    final createdAt = data['createdAt'] is Timestamp
        ? (data['createdAt'] as Timestamp).toDate()
        : null;
    final estimatedValue = (data['estimatedValue'] as num?)?.toDouble() ?? 0;
    final supervisorRequested = data['supervisorRequested'] == true;
    final orderCode = data['supervisorOrderCode']?.toString();
    final urgency = data['serviceUrgency'] as String? ?? 'Sin urgencia';
    final category = data['serviceInterest'] as String? ?? 'Sin categoría';
    final status = data['status']?.toString().toLowerCase() ?? '';
    final commercialStage = data['commercialFlowStage']?.toString();
    final preferredProviderName =
        data['preferredProviderName']?.toString().trim() ?? '';
    final directedToProvider =
        (data['directedToProvider'] == true) ||
        preferredProviderName.isNotEmpty;
    final stageMeta = _mapCommercialStage(commercialStage, supervisorRequested);
    final canAddSupervisor =
        !supervisorRequested &&
        requestId.isNotEmpty &&
        status != 'completada' &&
        status != 'finalizada' &&
        status != 'cancelada';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: requestId.isEmpty
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SolicitudDetallePage(solicitudId: requestId),
                  ),
                );
              },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFDCE7DF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (orderCode != null && orderCode.isNotEmpty)
                    _Tag(
                      label: orderCode,
                      background: const Color(0xFFEAF5EE),
                      foreground: MisSolicitudesPage._brandGreen,
                    ),
                  _Tag(
                    label: category,
                    background: const Color(0xFFE9F3ED),
                    foreground: MisSolicitudesPage._brandGreenSoft,
                  ),
                  _Tag(
                    label: urgency,
                    background: isEmergency
                        ? const Color(0xFFFFE1D0)
                        : const Color(0xFFF2F4F7),
                    foreground: isEmergency
                        ? const Color(0xFFC24E00)
                        : const Color(0xFF4E5968),
                  ),
                  _Tag(
                    label: data['status']?.toString() ?? 'sin estado',
                    background: const Color(0xFFF2F4F7),
                    foreground: const Color(0xFF4E5968),
                  ),
                  if (stageMeta != null)
                    _Tag(
                      label: stageMeta.label,
                      background: stageMeta.background,
                      foreground: stageMeta.foreground,
                    ),
                  if (supervisorRequested)
                    const _Tag(
                      label: 'Con supervisión',
                      background: Color(0xFFE7F4EB),
                      foreground: MisSolicitudesPage._brandGreenSoft,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data['titulo']?.toString() ?? 'Solicitud',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.black38),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                data['descripcion']?.toString() ?? '',
                style: const TextStyle(color: Colors.black54, height: 1.35),
              ),
              if (preferredProviderName.isNotEmpty) ...[
                const SizedBox(height: 12),
                _CommercialHintCard(
                  title: directedToProvider
                      ? 'Proveedor objetivo'
                      : 'Marketplace abierto',
                  description: directedToProvider
                      ? 'Esta oportunidad está dirigida a $preferredProviderName y seguirá una ruta comercial asistida por SaneApp.'
                      : 'Esta solicitud está visible en el marketplace para recibir respuesta comercial.',
                  accent: const Color(0xFF0C4F31),
                ),
              ],
              if (stageMeta != null) ...[
                const SizedBox(height: 12),
                _CommercialStageStrip(stage: stageMeta),
              ],
              const SizedBox(height: 12),
              _RequestClosurePanel(requestId: requestId, data: data),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _InfoLine(
                      icon: Icons.location_on_outlined,
                      text: data['city']?.toString() ?? 'Sin ciudad',
                    ),
                  ),
                  Expanded(
                    child: _InfoLine(
                      icon: Icons.payments_outlined,
                      text: estimatedValue > 0
                          ? '${estimatedValue.toStringAsFixed(0)} COP'
                          : 'Sin valor estimado',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _InfoLine(
                icon: Icons.schedule_outlined,
                text: createdAt != null
                    ? 'Publicada ${createdAt.toLocal().toString().substring(0, 16)}'
                    : 'Fecha pendiente',
              ),
              if (canAddSupervisor) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _requestSupervisor(
                          context,
                          requestId,
                          'prequote_diagnostic',
                        ),
                        icon: const Icon(Icons.fact_check_outlined),
                        label: const Text('Solicitar preinspección técnica'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _requestSupervisor(
                          context,
                          requestId,
                          'execution_traceability',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: MisSolicitudesPage._brandGreen,
                        ),
                        icon: const Icon(Icons.verified_user_outlined),
                        label: const Text('Solicitar supervisión y calidad'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestSupervisor(
    BuildContext context,
    String requestId,
    String type,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Solicitar supervisión SaneApp'),
        content: Text(
          type == 'execution_traceability'
              ? 'Se solicitará supervisión de ejecución, buenas prácticas y evaluación de calidad del proveedor por personal técnico directo de SaneApp.'
              : 'Se solicitará preinspección técnica por personal directo de SaneApp para levantar condiciones reales antes de cotizar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    final isExecutionTraceability =
        type == 'execution_traceability' || type == 'completo';
    final cost = isExecutionTraceability ? 150000.0 : 80000.0;
    final preferredProviderId = data['preferredProviderId']?.toString();
    final preferredProviderName = data['preferredProviderName']?.toString();
    final preferredProviderServiceId = data['preferredProviderServiceId']
        ?.toString();
    final preferredProviderServiceTitle = data['preferredProviderServiceTitle']
        ?.toString();
    final preferredProviderServicePriceType =
        data['preferredProviderServicePriceType']?.toString();
    final hasDirectedProvider =
        preferredProviderId != null && preferredProviderId.isNotEmpty;
    final commercialRouting = {
      'requestIntent': data['requestIntent']?.toString(),
      'requestSource': data['requestSource']?.toString(),
      'preferredProviderId': preferredProviderId,
      'preferredProviderName': preferredProviderName,
      'preferredProviderServiceId': preferredProviderServiceId,
      'preferredProviderServiceTitle': preferredProviderServiceTitle,
      'preferredProviderServicePriceType': preferredProviderServicePriceType,
      'serviceCategory': data['serviceInterest']?.toString(),
      'supervisorJourney': type,
      'directedToProvider': hasDirectedProvider,
    };
    final commercialFlowStage = hasDirectedProvider
        ? 'awaiting_supervisor_visit_for_provider_quote'
        : 'awaiting_supervisor_visit';

    try {
      await FirebaseFirestore.instance.collection('solicitudes').doc(requestId).set({
        'supervisorRequested': true,
        'supervisorType': type,
        'supervisionJourney': type,
        'supervisorCost': cost,
        'supervisorId': null,
        'supervisorName': null,
        'supervisorAssignedAt': null,
        'supervisorOrderCode': null,
        'supervisorStatus': 'pendiente_asignacion',
        'supervisorDispatchMode': 'pending_auto_dispatch',
        'supervisorDispatchReason': null,
        'supervisionProviderType': 'saneapp_staff',
        'supervisionServiceSummary': isExecutionTraceability
            ? 'Personal técnico directo de SaneApp acompañará la ejecución, validará buenas prácticas y emitirá evaluación de calidad del proveedor.'
            : 'Personal técnico directo de SaneApp realizará preinspección técnica, recopilación de información del punto y ficha previa a cotización.',
        'prequoteTechnicalSurveyRequired': !isExecutionTraceability,
        'providerQualityEvaluationRequired': isExecutionTraceability,
        'providerQualityEvaluationStatus': isExecutionTraceability
            ? 'pendiente'
            : null,
        'technicalSurveySheet': !isExecutionTraceability
            ? buildInitialTechnicalSurveySheet(
                city: data['city']?.toString(),
                address: data['operationAddress']?.toString(),
                serviceCategory: data['serviceInterest']?.toString(),
                urgency: data['serviceUrgency']?.toString(),
              )
            : null,
        'providerQualityEvaluation': isExecutionTraceability
            ? buildInitialProviderQualityEvaluation()
            : null,
        'commercialRouting': commercialRouting,
        'commercialFlowStage': commercialFlowStage,
        'commercialFlowUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isExecutionTraceability
                ? 'Supervisión de ejecución y calidad solicitada.'
                : 'Preinspección técnica solicitada.',
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No fue posible solicitar la supervisión.'),
        ),
      );
    }
  }
}

class _RequestClosurePanel extends StatelessWidget {
  const _RequestClosurePanel({required this.requestId, required this.data});

  final String requestId;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('ofertas')
          .where('solicitudId', isEqualTo: requestId)
          .snapshots(),
      builder: (context, offersSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('payments')
              .where('solicitudId', isEqualTo: requestId)
              .limit(1)
              .snapshots(),
          builder: (context, paymentsSnapshot) {
            final offers = offersSnapshot.data?.docs ?? const [];
            final paymentDoc = paymentsSnapshot.data?.docs.isNotEmpty == true
                ? paymentsSnapshot.data!.docs.first
                : null;
            final paymentData = paymentDoc?.data();
            final selectedOfferId = data['selectedOfferId']?.toString() ?? '';
            final selectedProviderId =
                data['selectedProveedorId']?.toString() ?? '';
            final selectedOffer = offers
                .cast<QueryDocumentSnapshot<Map<String, dynamic>>?>()
                .firstWhere(
                  (doc) => doc?.id == selectedOfferId,
                  orElse: () => null,
                );
            final selectedOfferData = selectedOffer?.data();
            final awarded =
                selectedOfferId.isNotEmpty || selectedProviderId.isNotEmpty;
            final providerName =
                selectedOfferData?['providerName']?.toString() ??
                data['preferredProviderName']?.toString() ??
                'proveedor seleccionado';
            final providerId =
                selectedOfferData?['proveedorId']?.toString() ??
                selectedProviderId;
            final paymentStatus = _normalizeCommercialPaymentStatus(
              paymentData?['paymentStatus'] ?? data['paymentStatus'],
            );
            final ratingValue = (data['customerRating'] as num?)?.toDouble();
            final rated = ratingValue != null && ratingValue > 0;
            final ratingEligible =
                providerId.isNotEmpty &&
                (paymentStatus == 'liberado' ||
                    _isCommercialTerminalStatus(data['status']));

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBF8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE1EADF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cierre comercial y económico',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ClosureChip(
                        icon: Icons.request_quote_outlined,
                        label: '${offers.length} ofertas',
                        tint: const Color(0xFF0C4F31),
                      ),
                      _ClosureChip(
                        icon: awarded
                            ? Icons.handshake_outlined
                            : Icons.hourglass_bottom_outlined,
                        label: awarded
                            ? 'Adjudicada a $providerName'
                            : 'Adjudicación pendiente',
                        tint: awarded
                            ? const Color(0xFF16633D)
                            : const Color(0xFF8A5E00),
                      ),
                      _ClosureChip(
                        icon: _paymentStatusIcon(paymentStatus),
                        label: _paymentStatusLabel(paymentStatus),
                        tint: _paymentStatusColor(paymentStatus),
                      ),
                      _ClosureChip(
                        icon: rated
                            ? Icons.star_rounded
                            : Icons.rate_review_outlined,
                        label: rated
                            ? 'Calificado ${ratingValue.toStringAsFixed(1)}'
                            : ratingEligible
                            ? 'Calificación pendiente'
                            : 'Calificación no habilitada',
                        tint: rated
                            ? const Color(0xFFB77900)
                            : ratingEligible
                            ? const Color(0xFF8A5E00)
                            : const Color(0xFF6E7A73),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _buildClosureNarrative(
                      offersCount: offers.length,
                      awarded: awarded,
                      providerName: providerName,
                      paymentStatus: paymentStatus,
                      rated: rated,
                    ),
                    style: const TextStyle(color: Colors.black54, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (offers.isNotEmpty && !awarded)
                        OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/ofertas_recibidas',
                          ),
                          icon: const Icon(Icons.compare_arrows_rounded),
                          label: const Text('Revisar ofertas'),
                        ),
                      if (rated)
                        Chip(
                          avatar: const Icon(Icons.star_rounded, size: 18),
                          label: Text(
                            'Tu comentario: ${data['customerReview']?.toString().trim().isNotEmpty == true ? data['customerReview'] : 'registrado'}',
                          ),
                        ),
                      if (ratingEligible && !rated)
                        FilledButton.icon(
                          onPressed: () => _showRatingDialog(
                            context,
                            providerId: providerId,
                            providerName: providerName,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: MisSolicitudesPage._brandGreen,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.rate_review_outlined),
                          label: const Text('Calificar cierre'),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showRatingDialog(
    BuildContext context, {
    required String providerId,
    required String providerName,
  }) async {
    double rating = 5;
    final reviewController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Calificar a $providerName'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Registra cómo cerró comercialmente el servicio para que la trazabilidad del negocio quede completa.',
                    style: TextStyle(height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 4,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      return IconButton(
                        onPressed: () {
                          setDialogState(() => rating = star.toDouble());
                        },
                        icon: Icon(
                          rating >= star
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xFFB77900),
                        ),
                      );
                    }),
                  ),
                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText:
                          'Comentario opcional sobre cierre, cumplimiento o experiencia.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm != true) {
      reviewController.dispose();
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('solicitudes')
          .doc(requestId)
          .set({
            'selectedProveedorId': providerId,
            'customerRating': rating,
            'customerRatingStatus': 'submitted',
            'customerReview': reviewController.text.trim(),
            'customerRatedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Calificación registrada.')));
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No fue posible guardar la calificación.'),
        ),
      );
    } finally {
      reviewController.dispose();
    }
  }
}

class _CommercialStageMeta {
  final String label;
  final String description;
  final int progress;
  final Color foreground;
  final Color background;

  const _CommercialStageMeta({
    required this.label,
    required this.description,
    required this.progress,
    required this.foreground,
    required this.background,
  });
}

_CommercialStageMeta? _mapCommercialStage(
  String? stage,
  bool supervisorRequested,
) {
  switch (stage) {
    case 'awaiting_provider_response':
      return const _CommercialStageMeta(
        label: 'Esperando respuesta comercial',
        description:
            'SaneApp ya envió la solicitud al proveedor objetivo y ahora se espera reacción comercial.',
        progress: 1,
        foreground: Color(0xFF0C4F31),
        background: Color(0xFFE8F4EC),
      );
    case 'awaiting_provider_quote':
      return const _CommercialStageMeta(
        label: 'Esperando cotización',
        description:
            'La ruta comercial está dirigida y se espera la propuesta económica del proveedor.',
        progress: 1,
        foreground: Color(0xFF115D3A),
        background: Color(0xFFE7F4EB),
      );
    case 'awaiting_supervisor_visit':
      return const _CommercialStageMeta(
        label: 'Pendiente visita técnica',
        description:
            'SaneApp debe levantar condiciones reales antes de seguir la conversación comercial.',
        progress: 1,
        foreground: Color(0xFF8A5E00),
        background: Color(0xFFFFF4D8),
      );
    case 'awaiting_supervisor_visit_for_provider_quote':
      return const _CommercialStageMeta(
        label: 'Visita previa antes de cotizar',
        description:
            'La solicitud ya está dirigida al proveedor y se espera la visita técnica de SaneApp.',
        progress: 1,
        foreground: Color(0xFF8A5E00),
        background: Color(0xFFFFF4D8),
      );
    case 'technical_sheet_ready_for_provider_quote':
      return const _CommercialStageMeta(
        label: 'Proveedor listo para cotizar',
        description:
            'La ficha técnica ya quedó lista y SaneApp puede empujar la propuesta económica del proveedor.',
        progress: 2,
        foreground: Color(0xFF16633D),
        background: Color(0xFFE6F5EA),
      );
    case 'technical_sheet_ready_for_generator_review':
      return const _CommercialStageMeta(
        label: 'Ficha lista para revisión',
        description:
            'La visita técnica ya produjo material útil para decidir el siguiente paso comercial.',
        progress: 2,
        foreground: Color(0xFF1C6A8C),
        background: Color(0xFFE7F3F9),
      );
    case 'open_marketplace':
      return const _CommercialStageMeta(
        label: 'Abierta al marketplace',
        description:
            'La oportunidad sigue abierta para recibir interés y ofertas del mercado.',
        progress: 0,
        foreground: Color(0xFF4E5968),
        background: Color(0xFFF2F4F7),
      );
    default:
      if (supervisorRequested) {
        return const _CommercialStageMeta(
          label: 'Supervisión activada',
          description:
              'La solicitud ya tiene apoyo técnico de SaneApp, aunque la etapa comercial aún no esté etiquetada.',
          progress: 1,
          foreground: Color(0xFF1C6A8C),
          background: Color(0xFFE7F3F9),
        );
      }
      return null;
  }
}

class _CommercialHintCard extends StatelessWidget {
  final String title;
  final String description;
  final Color accent;

  const _CommercialHintCard({
    required this.title,
    required this.description,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w800, color: accent),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(color: Colors.black54, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _ClosureChip extends StatelessWidget {
  const _ClosureChip({
    required this.icon,
    required this.label,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: tint),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: tint, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _CommercialStageStrip extends StatelessWidget {
  final _CommercialStageMeta stage;

  const _CommercialStageStrip({required this.stage});

  @override
  Widget build(BuildContext context) {
    const steps = ['Solicitud', 'Soporte SaneApp', 'Cotización', 'Cierre'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: stage.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stage.description,
            style: TextStyle(color: stage.foreground, height: 1.35),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(steps.length, (index) {
              final done = index <= stage.progress;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == steps.length - 1 ? 0 : 6,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 6,
                    ),
                    decoration: BoxDecoration(
                      color: done
                          ? stage.foreground.withValues(alpha: 0.16)
                          : Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      steps[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: done
                            ? stage.foreground
                            : const Color(0xFF7A858F),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.black54)),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _Tag({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

String _normalizeCommercialPaymentStatus(Object? raw) {
  final value = raw?.toString().trim().toLowerCase() ?? '';
  if (value.contains('custodia')) {
    return 'en_custodia';
  }
  if (value.isEmpty) {
    return 'pendiente';
  }
  return value;
}

bool _isCommercialTerminalStatus(Object? raw) {
  final value = raw?.toString().trim().toLowerCase() ?? '';
  return value == 'finalizada' || value == 'completada';
}

String _paymentStatusLabel(String status) {
  switch (status) {
    case 'liberado':
      return 'Pago liberado';
    case 'en_disputa':
      return 'Pago en disputa';
    case 'en_custodia':
      return 'Pago en custodia';
    case 'pago_confirmado':
      return 'Pago confirmado';
    default:
      return 'Pago pendiente';
  }
}

IconData _paymentStatusIcon(String status) {
  switch (status) {
    case 'liberado':
      return Icons.verified_outlined;
    case 'en_disputa':
      return Icons.gpp_maybe_outlined;
    case 'en_custodia':
      return Icons.account_balance_wallet_outlined;
    case 'pago_confirmado':
      return Icons.payments_outlined;
    default:
      return Icons.hourglass_bottom_outlined;
  }
}

Color _paymentStatusColor(String status) {
  switch (status) {
    case 'liberado':
      return const Color(0xFF2E7D32);
    case 'en_disputa':
      return const Color(0xFFC24E00);
    case 'en_custodia':
      return const Color(0xFF1565C0);
    case 'pago_confirmado':
      return const Color(0xFF0C4F31);
    default:
      return const Color(0xFF8A5E00);
  }
}

String _buildClosureNarrative({
  required int offersCount,
  required bool awarded,
  required String providerName,
  required String paymentStatus,
  required bool rated,
}) {
  if (rated) {
    return 'La solicitud ya cerró ciclo comercial: hubo adjudicación, el estado económico está visible y tu evaluación del proveedor quedó registrada.';
  }
  if (paymentStatus == 'en_disputa') {
    return 'El pago quedó protegido en disputa. SaneApp debe revisar el caso, la evidencia y el alcance ejecutado antes de decidir liberación o ajuste.';
  }
  if (paymentStatus == 'liberado') {
    return 'El negocio ya avanzó hasta liberación de pago. Si la experiencia fue satisfactoria, el siguiente paso es dejar la calificación del proveedor.';
  }
  if (paymentStatus == 'en_custodia') {
    return 'La propuesta ya fue adjudicada y SaneApp mantiene el dinero en custodia mientras se valida cumplimiento antes de liberarlo.';
  }
  if (awarded) {
    return 'La solicitud ya quedó adjudicada a $providerName. El carril visible que sigue es pago, validación y cierre final.';
  }
  if (offersCount > 0) {
    return 'Ya recibiste propuestas comerciales. Desde aquí puedes seguir cuándo adjudicas, cómo avanza el pago y cuándo se habilita la calificación.';
  }
  return 'Todavía no hay ofertas recibidas, por lo que el cierre económico seguirá pendiente hasta que entre una propuesta comercial.';
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment_late_outlined,
              size: 48,
              color: MisSolicitudesPage._brandGreenSoft,
            ),
            const SizedBox(height: 14),
            const Text(
              'Aún no tienes solicitudes creadas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Publica tu primera solicitud para comenzar a recibir ofertas y operar el marketplace desde tu panel cliente.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/crear_solicitud'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MisSolicitudesPage._brandGreen,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add_task),
              label: const Text('Crear solicitud'),
            ),
          ],
        ),
      ),
    );
  }
}
