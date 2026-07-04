import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../billing/billing_model.dart';
import '../chat/transaction_chat_page.dart';
import '../provider/provider_quote_pdf_service.dart';
import '../shared/request_image_gallery.dart';
import '../supervision/supervision_artifacts.dart';

class SolicitudDetallePage extends StatelessWidget {
  final String solicitudId;

  const SolicitudDetallePage({super.key, required this.solicitudId});

  static const _brandGreen = Color(0xFF0C4F31);
  static const _brandGreenSoft = Color(0xFF1E7A4B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      appBar: AppBar(
        title: const Text('Detalle de solicitud'),
        backgroundColor: _brandGreen,
        foregroundColor: Colors.white,
      ),
      body: Firebase.apps.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Detalle no disponible mientras Firebase no esté inicializado.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('solicitudes')
                  .doc(solicitudId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data?.data();
                if (data == null) {
                  return const Center(
                    child: Text('No se encontró la solicitud.'),
                  );
                }
                final isEmergency = data['type'] == 'emergency';
                final createdAt = data['createdAt'] is Timestamp
                    ? (data['createdAt'] as Timestamp).toDate()
                    : null;
                final deadline = data['deadline'] is Timestamp
                    ? (data['deadline'] as Timestamp).toDate()
                    : null;
                final supervisorRequested = data['supervisorRequested'] == true;
                final supervisorType = data['supervisorType']?.toString();
                final supervisorStatus = data['supervisorStatus']?.toString();
                final supervisorOrderCode = data['supervisorOrderCode']
                    ?.toString();
                final supervisorCost =
                    (data['supervisorCost'] as num?)?.toDouble() ?? 0;
                final providerQualityEvaluationRequired =
                    data['providerQualityEvaluationRequired'] == true;
                final providerQualityEvaluationStatus =
                    data['providerQualityEvaluationStatus']?.toString();
                final supervisionServiceSummary =
                    data['supervisionServiceSummary']?.toString();
                final technicalSurveySheet = resolveTechnicalSurveySheet(data);
                final providerQualityEvaluation =
                    resolveProviderQualityEvaluation(data);
                final requestImageUrls =
                    (data['requestImageUrls'] as List?)?.cast<String>() ??
                    const <String>[];
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _HeaderCard(
                      title: data['titulo']?.toString() ?? 'Solicitud',
                      category:
                          data['serviceInterest']?.toString() ??
                          'Sin categoría',
                      status: data['status']?.toString() ?? 'Sin estado',
                      isEmergency: isEmergency,
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Resumen operativo',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['descripcion']?.toString() ?? ''),
                          const SizedBox(height: 12),
                          _InfoRow(
                            label: 'Ciudad',
                            value: data['city']?.toString() ?? '-',
                          ),
                          _InfoRow(
                            label: 'Dirección',
                            value: data['operationAddress']?.toString() ?? '-',
                          ),
                          _InfoRow(
                            label: 'Urgencia',
                            value: data['serviceUrgency']?.toString() ?? '-',
                          ),
                          _InfoRow(
                            label: 'Subcategoría',
                            value:
                                data['serviceSubcategory']
                                        ?.toString()
                                        .trim()
                                        .isNotEmpty ==
                                    true
                                ? data['serviceSubcategory']!.toString()
                                : '-',
                          ),
                          _InfoRow(
                            label: 'Frecuencia',
                            value: data['contractFrequency']?.toString() ?? '-',
                          ),
                          if (data['commercialMatching'] is Map)
                            _InfoRow(
                              label: 'Matching premium',
                              value:
                                  '${((data['commercialMatching'] as Map)['matchedProvidersCount'] as num?)?.toInt() ?? 0} proveedores · ${((data['commercialMatching'] as Map)['matchedServicesCount'] as num?)?.toInt() ?? 0} servicios',
                            ),
                          _InfoRow(
                            label: 'Valor estimado',
                            value:
                                ((data['estimatedValue'] as num?)?.toDouble() ??
                                        0) >
                                    0
                                ? '${((data['estimatedValue'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)} COP'
                                : '-',
                          ),
                          if (deadline != null)
                            _InfoRow(
                              label: 'Cierre',
                              value:
                                  '${deadline.day}/${deadline.month}/${deadline.year} ${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}',
                            ),
                          if (createdAt != null)
                            _InfoRow(
                              label: 'Creada',
                              value:
                                  '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _CommercialChatCard(
                      solicitudId: solicitudId,
                      requestData: data,
                    ),
                    const SizedBox(height: 16),
                    if (requestImageUrls.isNotEmpty) ...[
                      _SectionCard(
                        title: 'Imágenes adjuntas',
                        child: RequestImageGallery(
                          imageUrls: requestImageUrls,
                          title: 'Referencias cargadas con la solicitud',
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _SupervisorSectionCard(
                      solicitudId: solicitudId,
                      requestData: data,
                      status: data['status']?.toString(),
                      supervisorRequested: supervisorRequested,
                      supervisorType: supervisorType,
                      supervisorStatus: supervisorStatus,
                      supervisorOrderCode: supervisorOrderCode,
                      supervisorCost: supervisorCost,
                      providerQualityEvaluationRequired:
                          providerQualityEvaluationRequired,
                      providerQualityEvaluationStatus:
                          providerQualityEvaluationStatus,
                      supervisionServiceSummary: supervisionServiceSummary,
                    ),
                    if (technicalSurveySheet != null) ...[
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Ficha técnica previa a cotización',
                        child: TechnicalSurveySheetCard(
                          sheet: technicalSurveySheet,
                        ),
                      ),
                    ],
                    if (providerQualityEvaluation != null) ...[
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Evaluación de calidad del proveedor',
                        child: ProviderQualityEvaluationCard(
                          evaluation: providerQualityEvaluation,
                        ),
                      ),
                    ],
                    if (resolveSupervisorActa(data, finalActa: false) != null ||
                        resolveSupervisorActa(data, finalActa: true) != null ||
                        resolveSupervisorVisitLocation(data) != null ||
                        resolveSupervisionLogEntries(data).isNotEmpty ||
                        resolveSupervisorEvidenceUrls(data).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SupervisorSupportCard(requestData: data),
                    ],
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Timeline',
                      child: _Timeline(
                        status: data['status']?.toString(),
                        selectedProveedorId: data['selectedProveedorId']
                            ?.toString(),
                        supervisorStatus: supervisorStatus,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _CommercialDossierCard(solicitudId: solicitudId),
                    const SizedBox(height: 16),
                    _BillingDocumentsCard(solicitudId: solicitudId),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Ofertas y adjudicación',
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('ofertas')
                            .where('solicitudId', isEqualTo: solicitudId)
                            .snapshots(),
                        builder: (context, offersSnapshot) {
                          final offers = offersSnapshot.data?.docs ?? const [];
                          final directAcceptance =
                              data['directAcceptance'] == true;
                          final selectedProviderId = data['selectedProveedorId']
                              ?.toString();
                          if (offers.isEmpty &&
                              directAcceptance &&
                              selectedProviderId != null &&
                              selectedProviderId.isNotEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF5EE),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFCFE2D5),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        color: _brandGreenSoft,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Aceptación directa del proveedor',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  _InfoRow(
                                    label: 'Proveedor asignado',
                                    value: selectedProviderId.substring(0, 6),
                                  ),
                                  const _InfoRow(
                                    label: 'Modalidad',
                                    value:
                                        'Aceptación directa desde marketplace',
                                  ),
                                  _InfoRow(
                                    label: 'Estado',
                                    value: data['status']?.toString() ?? '-',
                                  ),
                                ],
                              ),
                            );
                          }
                          if (offers.isEmpty) {
                            return const Text(
                              'Aún no hay ofertas para esta solicitud.',
                            );
                          }
                          final sorted = [...offers]
                            ..sort((a, b) {
                              final priceA =
                                  (a.data()['price'] as num?)?.toDouble() ?? 0;
                              final priceB =
                                  (b.data()['price'] as num?)?.toDouble() ?? 0;
                              return priceA.compareTo(priceB);
                            });
                          return Column(
                            children: sorted.map((offerDoc) {
                              final offer = offerDoc.data();
                              final isSelected =
                                  data['selectedOfferId'] == offerDoc.id;
                              final providerSnapshot =
                                  (offer['providerSnapshot'] as Map?)
                                      ?.cast<String, dynamic>();
                              final companyName =
                                  providerSnapshot?['companyName']?.toString();
                              final subtotal = (offer['subtotal'] as num?)
                                  ?.toDouble();
                              final pricingDescription =
                                  offer['pricingDescription']?.toString() ??
                                  offer['pricingUnit']?.toString() ??
                                  'Precio fijo por servicio';
                              final pricingBreakdown = offer['pricingBreakdown']
                                  ?.toString();
                              final serviceQuantity =
                                  (offer['serviceQuantity'] as num?)
                                      ?.toDouble();
                              final quantityLabel =
                                  offer['quantityLabel']?.toString() ??
                                  'servicio';
                              final appliesIva = offer['appliesIva'] == true;
                              final ivaRate =
                                  (offer['ivaRate'] as num?)?.toDouble() ?? 0;
                              final taxAmount = (offer['taxAmount'] as num?)
                                  ?.toDouble();
                              final totalAmount =
                                  (offer['totalAmount'] as num?)?.toDouble() ??
                                  (offer['price'] as num?)?.toDouble() ??
                                  0;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFEAF5EE)
                                      : const Color(0xFFF9FBFA),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFCFE2D5)
                                        : const Color(0xFFE2EAE4),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if ((providerSnapshot?['logoUrl']
                                                ?.toString()
                                                .isNotEmpty ??
                                            false))
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: 10,
                                            ),
                                            child: CircleAvatar(
                                              backgroundImage: NetworkImage(
                                                providerSnapshot!['logoUrl']
                                                    .toString(),
                                              ),
                                            ),
                                          ),
                                        Expanded(
                                          child: Text(
                                            companyName != null &&
                                                    companyName.isNotEmpty
                                                ? companyName
                                                : 'Proveedor ${offer['proveedorId']?.toString().substring(0, 6) ?? '-'}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          const _Badge(
                                            label: 'Adjudicada',
                                            background: Color(0xFFE7F4EB),
                                            foreground: _brandGreenSoft,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if ((offer['quoteNumber']
                                            ?.toString()
                                            .isNotEmpty ??
                                        false))
                                      _InfoRow(
                                        label: 'Cotización',
                                        value: offer['quoteNumber'].toString(),
                                      ),
                                    if ((offer['summary']
                                            ?.toString()
                                            .isNotEmpty ??
                                        false))
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Text(
                                          offer['summary'].toString(),
                                        ),
                                      ),
                                    _InfoRow(
                                      label: 'Precio del servicio',
                                      value: pricingDescription,
                                    ),
                                    if (pricingBreakdown != null &&
                                        pricingBreakdown.isNotEmpty)
                                      _InfoRow(
                                        label: 'Tarifa base',
                                        value: pricingBreakdown,
                                      ),
                                    if (serviceQuantity != null)
                                      _InfoRow(
                                        label: 'Cantidad facturable',
                                        value:
                                            '${serviceQuantity == serviceQuantity.truncateToDouble() ? serviceQuantity.toStringAsFixed(0) : serviceQuantity.toStringAsFixed(2)} $quantityLabel',
                                      ),
                                    _InfoRow(
                                      label: 'Total',
                                      value:
                                          '${totalAmount.toStringAsFixed(0)} COP',
                                    ),
                                    if (subtotal != null)
                                      _InfoRow(
                                        label: 'Subtotal',
                                        value:
                                            '${subtotal.toStringAsFixed(0)} COP',
                                      ),
                                    if (taxAmount != null)
                                      _InfoRow(
                                        label: appliesIva
                                            ? 'IVA (${ivaRate.toStringAsFixed(0)}%)'
                                            : 'IVA no aplica',
                                        value: appliesIva
                                            ? '${taxAmount.toStringAsFixed(0)} COP'
                                            : '0 COP',
                                      ),
                                    _InfoRow(
                                      label: 'Tiempo estimado',
                                      value:
                                          offer['tiempoEstimado']?.toString() ??
                                          '-',
                                    ),
                                    _InfoRow(
                                      label: 'Garantía',
                                      value:
                                          offer['garantia']?.toString() ?? '-',
                                    ),
                                    _InfoRow(
                                      label: 'Pago',
                                      value:
                                          offer['paymentTerms']?.toString() ??
                                          '-',
                                    ),
                                    _InfoRow(
                                      label: 'Vigencia',
                                      value: (() {
                                        final validUntil = offer['validUntil'];
                                        if (validUntil is Timestamp) {
                                          final date = validUntil.toDate();
                                          return '${date.day}/${date.month}/${date.year}';
                                        }
                                        final validityDays =
                                            offer['validityDays'];
                                        if (validityDays != null) {
                                          return '$validityDays días';
                                        }
                                        return '-';
                                      })(),
                                    ),
                                    _InfoRow(
                                      label: 'Calificación',
                                      value:
                                          ((offer['calificacionProveedor']
                                                          as num?)
                                                      ?.toDouble() ??
                                                  0) >
                                              0
                                          ? ((offer['calificacionProveedor']
                                                    as num?)!
                                                .toDouble()
                                                .toStringAsFixed(1))
                                          : '-',
                                    ),
                                    if ((offer['deliverables']
                                            ?.toString()
                                            .isNotEmpty ??
                                        false))
                                      _InfoRow(
                                        label: 'Entregables',
                                        value: offer['deliverables'].toString(),
                                      ),
                                    if ((offer['serviceConditions']
                                            ?.toString()
                                            .isNotEmpty ??
                                        false))
                                      _InfoRow(
                                        label: 'Condiciones',
                                        value: offer['serviceConditions']
                                            .toString(),
                                      ),
                                    if ((offer['exclusions']
                                            ?.toString()
                                            .isNotEmpty ??
                                        false))
                                      _InfoRow(
                                        label: 'Exclusiones',
                                        value: offer['exclusions'].toString(),
                                      ),
                                    if ((offer['observations']
                                            ?.toString()
                                            .isNotEmpty ??
                                        false))
                                      _InfoRow(
                                        label: 'Observaciones',
                                        value: offer['observations'].toString(),
                                      ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      alignment: WrapAlignment.end,
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () async {
                                            await ProviderQuotePdfService.downloadQuotePdf(
                                              offerData: offer,
                                              requestData: data,
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.download_outlined,
                                          ),
                                          label: const Text('Descargar PDF'),
                                        ),
                                        FilledButton.icon(
                                          onPressed: () {
                                            final profileSnapshot =
                                                (data['profileSnapshot']
                                                        as Map?)
                                                    ?.cast<String, dynamic>();
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => TransactionChatPage(
                                                  requestId: solicitudId,
                                                  requestTitle:
                                                      data['titulo']
                                                          ?.toString() ??
                                                      'Solicitud',
                                                  generatorId:
                                                      data['generadorId']
                                                          ?.toString() ??
                                                      '',
                                                  providerId:
                                                      offer['proveedorId']
                                                          ?.toString() ??
                                                      '',
                                                  generatorLabel:
                                                      profileSnapshot?['companyName']
                                                          ?.toString() ??
                                                      data['contactName']
                                                          ?.toString() ??
                                                      'Generador',
                                                  providerLabel:
                                                      companyName != null &&
                                                          companyName.isNotEmpty
                                                      ? companyName
                                                      : 'Proveedor',
                                                ),
                                              ),
                                            );
                                          },
                                          style: FilledButton.styleFrom(
                                            backgroundColor:
                                                SolicitudDetallePage
                                                    ._brandGreen,
                                            foregroundColor: Colors.white,
                                          ),
                                          icon: const Icon(
                                            Icons.chat_bubble_outline,
                                          ),
                                          label: const Text('Chat comercial'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _CommercialChatCard extends StatelessWidget {
  const _CommercialChatCard({
    required this.solicitudId,
    required this.requestData,
  });

  final String solicitudId;
  final Map<String, dynamic> requestData;

  @override
  Widget build(BuildContext context) {
    final requestTitle = requestData['titulo']?.toString() ?? 'Solicitud';

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('commercial_chats')
          .doc(solicitudId)
          .snapshots(),
      builder: (context, snapshot) {
        final chatData = snapshot.data?.data();
        final profileSnapshot = (requestData['profileSnapshot'] as Map?)
            ?.cast<String, dynamic>();
        final generatorId =
            chatData?['generatorId']?.toString() ??
            requestData['generadorId']?.toString() ??
            '';
        final providerId =
            chatData?['providerId']?.toString() ??
            requestData['selectedProveedorId']?.toString() ??
            requestData['preferredProviderId']?.toString() ??
            '';
        final generatorLabel =
            chatData?['generatorLabel']?.toString() ??
            profileSnapshot?['companyName']?.toString() ??
            requestData['contactName']?.toString() ??
            'Generador';
        final providerLabel =
            chatData?['providerLabel']?.toString() ??
            requestData['preferredProviderName']?.toString() ??
            'Proveedor';
        final lastMessage = chatData?['lastMessage']?.toString() ?? '';
        final canOpen = generatorId.isNotEmpty && providerId.isNotEmpty;

        return _SectionCard(
          title: 'Chat comercial',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                canOpen
                    ? 'Centraliza aclaraciones de alcance, tiempos, condiciones y acuerdos preliminares con el proveedor dentro de la misma solicitud.'
                    : 'Cuando un proveedor abra conversación o quede asociado a esta solicitud, el canal comercial aparecerá aquí.',
                style: const TextStyle(color: Colors.black54, height: 1.4),
              ),
              if (lastMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FBF9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDCE7DF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Último mensaje de ${chatData?['providerLabel']?.toString() ?? providerLabel}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lastMessage,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: canOpen
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TransactionChatPage(
                              requestId: solicitudId,
                              requestTitle: requestTitle,
                              generatorId: generatorId,
                              providerId: providerId,
                              generatorLabel: generatorLabel,
                              providerLabel: providerLabel,
                            ),
                          ),
                        );
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: SolicitudDetallePage._brandGreen,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(canOpen ? 'Abrir conversación' : 'Chat pendiente'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SupervisorSectionCard extends StatelessWidget {
  final String solicitudId;
  final Map<String, dynamic> requestData;
  final String? status;
  final bool supervisorRequested;
  final String? supervisorType;
  final String? supervisorStatus;
  final String? supervisorOrderCode;
  final double supervisorCost;
  final bool providerQualityEvaluationRequired;
  final String? providerQualityEvaluationStatus;
  final String? supervisionServiceSummary;

  const _SupervisorSectionCard({
    required this.solicitudId,
    required this.requestData,
    required this.status,
    required this.supervisorRequested,
    required this.supervisorType,
    required this.supervisorStatus,
    required this.supervisorOrderCode,
    required this.supervisorCost,
    required this.providerQualityEvaluationRequired,
    required this.providerQualityEvaluationStatus,
    required this.supervisionServiceSummary,
  });

  bool get _canRequestSupervisor {
    final normalized = status?.toLowerCase() ?? '';
    return !supervisorRequested &&
        normalized != 'completada' &&
        normalized != 'cancelada' &&
        normalized != 'finalizada';
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Supervisión SaneApp',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (supervisorRequested) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Badge(
                  label: _mapSupervisorTypeLabel(supervisorType),
                  background: const Color(0xFFE9F3ED),
                  foreground: SolicitudDetallePage._brandGreenSoft,
                ),
                _Badge(
                  label: _mapSupervisorStatusLabel(supervisorStatus),
                  background: const Color(0xFFF1F5F9),
                  foreground: const Color(0xFF4E5968),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Modalidad',
              value: _mapSupervisorTypeLabel(supervisorType),
            ),
            _InfoRow(
              label: 'Estado',
              value: _mapSupervisorStatusLabel(supervisorStatus),
            ),
            _InfoRow(
              label: 'Orden supervisor',
              value:
                  supervisorOrderCode ?? 'Pendiente de asignación automática',
            ),
            _InfoRow(
              label: 'Costo estimado',
              value: supervisorCost > 0
                  ? '${supervisorCost.toStringAsFixed(0)} COP'
                  : 'Pendiente por confirmar',
            ),
            _InfoRow(
              label: 'Cobertura',
              value: _mapSupervisorCoverage(supervisorType),
            ),
            _InfoRow(
              label: 'Equipo asignado',
              value: 'Personal técnico directo de SaneApp',
            ),
            if (providerQualityEvaluationRequired)
              _InfoRow(
                label: 'Calidad del proveedor',
                value: _mapQualityEvaluationStatus(
                  providerQualityEvaluationStatus,
                ),
              ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBF9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDCE7DF)),
              ),
              child: Text(
                supervisionServiceSummary ??
                    'La supervisión la ejecuta personal directo de SaneApp: visita el punto, recopila información técnica real, brinda orientación breve al generador y deja evidencia para que la ejecución y la oferta del proveedor se apoyen en condiciones verificadas.',
                style: const TextStyle(color: Colors.black54, height: 1.4),
              ),
            ),
          ] else if (_canRequestSupervisor) ...[
            const Text(
              'Todavía puedes añadir supervisión a esta solicitud si necesitas verificación técnica, control de ejecución o respaldo de cierre.',
              style: TextStyle(color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _requestSupervisor(
                      context,
                      type: 'prequote_diagnostic',
                    ),
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('Preinspección'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _requestSupervisor(
                      context,
                      type: 'execution_traceability',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: SolicitudDetallePage._brandGreen,
                    ),
                    icon: const Icon(Icons.verified_user_outlined),
                    label: const Text('Ejecución y calidad'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Preinspección: diagnóstico técnico previo a cotización. Ejecución y calidad: acompañamiento, evidencias y evaluación del proveedor.',
              style: TextStyle(
                color: Colors.black45,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ] else ...[
            const Text(
              'Esta solicitud ya no está en una fase compatible para agregar supervisión nueva.',
              style: TextStyle(color: Colors.black54, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _requestSupervisor(
    BuildContext context, {
    required String type,
  }) async {
    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Solicitar supervisión'),
        content: Text(
          type == 'completo'
              ? 'Se activará acompañamiento completo para esta solicitud.'
              : 'Se activará supervisión puntual para esta solicitud.',
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

    if (shouldContinue != true) {
      return;
    }

    final isExecutionTraceability =
        type == 'execution_traceability' || type == 'completo';
    final cost = isExecutionTraceability ? 150000.0 : 80000.0;

    try {
      await FirebaseFirestore.instance.collection('solicitudes').doc(solicitudId).set({
        'supervisorRequested': true,
        'supervisorType': type,
        'supervisorCost': cost,
        'supervisorId': null,
        'supervisorName': null,
        'supervisorAssignedAt': null,
        'supervisorOrderCode': null,
        'supervisorStatus': 'pendiente_asignacion',
        'supervisorDispatchMode': 'pending_auto_dispatch',
        'supervisorDispatchReason': null,
        'supervisionJourney': type,
        'supervisionProviderType': 'saneapp_staff',
        'supervisionServiceSummary': isExecutionTraceability
            ? 'Personal técnico directo de SaneApp acompañará la ejecución, verificará buenas prácticas del proveedor, registrará evidencias y emitirá evaluación de calidad del servicio.'
            : 'Personal técnico directo de SaneApp realizará visita previa, levantamiento técnico, registro fotográfico y ficha técnica para soportar la cotización.',
        'prequoteTechnicalSurveyRequired': !isExecutionTraceability,
        'providerQualityEvaluationRequired': isExecutionTraceability,
        'providerQualityEvaluationStatus': isExecutionTraceability
            ? 'pendiente'
            : null,
        'technicalSurveySheet': !isExecutionTraceability
            ? buildInitialTechnicalSurveySheet(
                city: requestData['city']?.toString(),
                address: requestData['operationAddress']?.toString(),
                serviceCategory: requestData['serviceInterest']?.toString(),
                urgency: requestData['serviceUrgency']?.toString(),
              )
            : null,
        'providerQualityEvaluation': isExecutionTraceability
            ? buildInitialProviderQualityEvaluation()
            : null,
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
          content: Text(
            'No fue posible activar la supervisión para esta solicitud.',
          ),
        ),
      );
    }
  }

  String _mapSupervisorTypeLabel(String? type) {
    switch (type) {
      case 'execution_traceability':
      case 'completo':
        return 'Supervisión de ejecución y calidad';
      case 'prequote_diagnostic':
      case 'puntual':
        return 'Preinspección técnica';
      default:
        return 'Sin supervisión';
    }
  }

  String _mapSupervisorStatusLabel(String? status) {
    switch (status) {
      case 'asignado':
        return 'Supervisor asignado';
      case 'pendiente_asignacion':
        return 'Pendiente asignación';
      case 'en_acompanamiento':
        return 'En acompañamiento';
      case 'verificado':
        return 'Verificado';
      case 'finalizado':
        return 'Finalizado';
      default:
        return 'Pendiente';
    }
  }

  String _mapSupervisorCoverage(String? type) {
    switch (type) {
      case 'execution_traceability':
      case 'completo':
        return 'Acompañamiento durante la ejecución, trazabilidad operativa y evaluación de calidad del proveedor.';
      case 'prequote_diagnostic':
      case 'puntual':
        return 'Visita técnica previa a cotización, levantamiento de condiciones reales y ficha de necesidades del servicio.';
      default:
        return 'No aplica';
    }
  }

  String _mapQualityEvaluationStatus(String? status) {
    switch (status) {
      case 'emitida':
        return 'Evaluación emitida';
      case 'en_revision':
        return 'Evaluación en revisión';
      default:
        return 'Pendiente de evaluación';
    }
  }
}

class _HeaderCard extends StatelessWidget {
  final String title;
  final String category;
  final String status;
  final bool isEmergency;

  const _HeaderCard({
    required this.title,
    required this.category,
    required this.status,
    required this.isEmergency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [
            SolicitudDetallePage._brandGreen,
            SolicitudDetallePage._brandGreenSoft,
          ],
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
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Badge(
                label: category,
                background: Colors.white24,
                foreground: Colors.white,
              ),
              _Badge(
                label: status,
                background: Colors.white24,
                foreground: Colors.white,
              ),
              if (isEmergency)
                const _Badge(
                  label: 'Emergencia',
                  background: Color(0xFFFFE1D0),
                  foreground: Color(0xFFC24E00),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final String? status;
  final String? selectedProveedorId;
  final String? supervisorStatus;

  const _Timeline({
    required this.status,
    required this.selectedProveedorId,
    required this.supervisorStatus,
  });

  @override
  Widget build(BuildContext context) {
    final steps = <Map<String, dynamic>>[
      {'label': 'Publicada', 'done': true},
      {'label': 'Recibiendo ofertas', 'done': true},
      {
        'label': 'Proveedor adjudicado',
        'done': selectedProveedorId != null && selectedProveedorId!.isNotEmpty,
      },
      {
        'label': 'Pago / confirmación',
        'done':
            status == 'pago_confirmado' ||
            status == 'en_ejecucion' ||
            status == 'completada',
      },
      {
        'label': 'Supervisión',
        'done':
            supervisorStatus == 'verificado' ||
            supervisorStatus == 'en_acompanamiento' ||
            supervisorStatus == 'finalizado',
      },
      {'label': 'Cierre', 'done': status == 'completada'},
    ];

    return Column(
      children: steps.map((step) {
        final done = step['done'] == true;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done ? SolicitudDetallePage._brandGreenSoft : Colors.black26,
          ),
          title: Text(step['label'] as String),
        );
      }).toList(),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _Badge({
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

class _CommercialDossierCard extends StatelessWidget {
  const _CommercialDossierCard({required this.solicitudId});

  final String solicitudId;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Expediente comercial',
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('solicitudes')
            .doc(solicitudId)
            .collection('commercial_events')
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? const [];
          final events = docs.map((doc) => doc.data()).toList()
            ..sort((a, b) {
              final aDate =
                  (a['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final bDate =
                  (b['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              return bDate.compareTo(aDate);
            });
          if (events.isEmpty) {
            return const Text(
              'El expediente empezará a llenarse cuando el negocio avance dentro de SaneApp.',
              style: TextStyle(color: Colors.black54, height: 1.4),
            );
          }

          return Column(
            children: events.take(8).map((event) {
              final createdAt = (event['createdAt'] as Timestamp?)?.toDate();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBF9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDCE7DF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['title']?.toString() ?? 'Evento',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      event['description']?.toString() ?? '',
                      style: const TextStyle(
                        color: Colors.black87,
                        height: 1.35,
                      ),
                    ),
                    if (createdAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _BillingDocumentsCard extends StatelessWidget {
  const _BillingDocumentsCard({required this.solicitudId});

  final String solicitudId;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Facturación del negocio',
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('billing_records')
            .where('requestId', isEqualTo: solicitudId)
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? const [];
          final records =
              docs
                  .map((doc) => BillingRecord.fromMap(doc.id, doc.data()))
                  .toList()
                ..sort((a, b) => b.date.compareTo(a.date));
          if (records.isEmpty) {
            return const Text(
              'Cuando el pago entre al flujo premium, SaneApp colgará aquí los documentos de facturación ligados a esta solicitud.',
              style: TextStyle(color: Colors.black54, height: 1.4),
            );
          }

          return Column(
            children: records.map((record) {
              final audience = record.audience == 'generador'
                  ? 'Visible al cliente'
                  : 'Soporte interno SaneApp';
              final typeLabel = record.documentType == 'saneapp_invoice'
                  ? 'Factura SaneApp'
                  : 'Soporte proveedor';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBF9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDCE7DF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            typeLabel,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        _Badge(
                          label: record.status,
                          background: const Color(0xFFEAF5EE),
                          foreground: SolicitudDetallePage._brandGreenSoft,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(label: 'Categoría', value: record.category),
                    if (record.subcategory.trim().isNotEmpty)
                      _InfoRow(
                        label: 'Subcategoría',
                        value: record.subcategory,
                      ),
                    _InfoRow(label: 'Invoice', value: record.invoiceNumber),
                    _InfoRow(label: 'Recibo', value: record.receiptNumber),
                    _InfoRow(
                      label: 'Monto',
                      value:
                          '${record.amount.toStringAsFixed(0)} ${record.currency}',
                    ),
                    _InfoRow(label: 'Audiencia', value: audience),
                    _InfoRow(label: 'Detalle', value: record.description),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
