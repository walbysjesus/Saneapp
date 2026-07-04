import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'provider_quote_pdf_service.dart';
import '../supervision/supervision_artifacts.dart';
import 'provider_access_guard.dart';
import 'provider_profile_status.dart';

class MisCotizacionesPage extends StatelessWidget {
  const MisCotizacionesPage({super.key});

  String _statusLabel(String? status) {
    switch (status) {
      case 'evaluacion':
        return 'En evaluacion';
      case 'no_seleccionada':
        return 'No seleccionada';
      case 'adjudicada':
        return 'Adjudicada';
      default:
        return 'Desconocido';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No autenticado.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Mis cotizaciones')),
      body: StreamBuilder<ProviderProfileStatus>(
        stream: const ProviderProfileStatusService().watchCurrentUserStatus(),
        builder: (context, statusSnapshot) {
          if (statusSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (statusSnapshot.hasError ||
              statusSnapshot.data?.accountStatus == 'offline') {
            return ProviderOfflineView(
              onRetry: () async {
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const MisCotizacionesPage(),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                );
              },
            );
          }
          final status = statusSnapshot.data;
          if (status == null || !status.canOperate) {
            return const ProviderProfileRequiredView(
              message:
                  'Tu registro de proveedor está incompleto. Completa los requisitos para ver tus cotizaciones.',
            );
          }
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('ofertas')
                .where('proveedorId', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return ProviderOfflineView(
                  title: 'No fue posible cargar tus cotizaciones',
                  message:
                      'La conexión con Firestore no está disponible en este momento. Inténtalo de nuevo cuando vuelva la red.',
                  onRetry: () async {
                    Navigator.of(context).pushReplacement(
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) =>
                            const MisCotizacionesPage(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  },
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No tienes cotizaciones enviadas.'),
                );
              }
              final ofertas = snapshot.data!.docs;
              return ListView.separated(
                itemCount: ofertas.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final data = ofertas[index].data() as Map<String, dynamic>;
                  final solicitudId = data['solicitudId']?.toString();
                  if (solicitudId == null || solicitudId.isEmpty) {
                    return _QuoteCard(
                      offerData: data,
                      requestData: null,
                      statusLabel: _statusLabel,
                    );
                  }
                  return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future: FirebaseFirestore.instance
                        .collection('solicitudes')
                        .doc(solicitudId)
                        .get(),
                    builder: (context, requestSnapshot) {
                      return _QuoteCard(
                        offerData: data,
                        requestData: requestSnapshot.data?.data(),
                        statusLabel: _statusLabel,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final Map<String, dynamic> offerData;
  final Map<String, dynamic>? requestData;
  final String Function(String?) statusLabel;

  const _QuoteCard({
    required this.offerData,
    required this.requestData,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final technicalSurveySheet = requestData == null
        ? null
        : resolveTechnicalSurveySheet(requestData!);
    final supportAvailable =
        requestData != null &&
        (resolveSupervisorActa(requestData!, finalActa: false) != null ||
            resolveSupervisorActa(requestData!, finalActa: true) != null ||
            resolveSupervisorVisitLocation(requestData!) != null ||
            resolveSupervisionLogEntries(requestData!).isNotEmpty ||
            resolveSupervisorEvidenceUrls(requestData!).isNotEmpty);
    final orderCode = requestData?['supervisorOrderCode']?.toString();
    final providerSnapshot = (offerData['providerSnapshot'] as Map?)
        ?.cast<String, dynamic>();
    final companyName = providerSnapshot?['companyName']?.toString();
    final quoteNumber = offerData['quoteNumber']?.toString();
    final pricingDescription =
        offerData['pricingDescription']?.toString() ??
        offerData['pricingUnit']?.toString() ??
        requestData?['preferredProviderServicePriceType']?.toString() ??
        'Precio fijo por servicio';
    final pricingBreakdown = offerData['pricingBreakdown']?.toString() ?? '-';
    final serviceQuantity = (offerData['serviceQuantity'] as num?)?.toDouble();
    final quantityLabel = offerData['quantityLabel']?.toString() ?? 'servicio';
    final appliesIva = offerData['appliesIva'] == true;
    final ivaRate = (offerData['ivaRate'] as num?)?.toDouble() ?? 0;
    final subtotal = (offerData['subtotal'] as num?)?.toDouble();
    final taxAmount = (offerData['taxAmount'] as num?)?.toDouble();
    final totalAmount =
        (offerData['totalAmount'] as num?)?.toDouble() ??
        (offerData['price'] as num?)?.toDouble();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.request_quote),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        requestData?['titulo']?.toString() ??
                            'Oferta: ${offerData['price'] ?? '-'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      if (companyName != null && companyName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(companyName),
                      ],
                      if (quoteNumber != null && quoteNumber.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Cotización: $quoteNumber',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                      if (orderCode != null && orderCode.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Orden supervisor: $orderCode',
                          style: const TextStyle(
                            color: Color(0xFF0C4F31),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Estado de oferta: ${statusLabel(offerData['status']?.toString())}',
                      ),
                      if ((offerData['summary']?.toString().isNotEmpty ??
                          false))
                        Text('Resumen: ${offerData['summary']}')
                      else
                        Text('Mensaje: ${offerData['message'] ?? ''}'),
                      Text('Precio del servicio: $pricingDescription'),
                      if (pricingBreakdown != '-')
                        Text('Tarifa base: $pricingBreakdown'),
                      if (serviceQuantity != null)
                        Text(
                          'Cantidad facturable: ${serviceQuantity == serviceQuantity.truncateToDouble() ? serviceQuantity.toStringAsFixed(0) : serviceQuantity.toStringAsFixed(2)} $quantityLabel',
                        ),
                      if (totalAmount != null)
                        Text(
                          'Total cotizado: ${totalAmount.toStringAsFixed(0)} COP',
                        ),
                      if (subtotal != null)
                        Text('Subtotal: ${subtotal.toStringAsFixed(0)} COP'),
                      if (taxAmount != null)
                        Text(
                          appliesIva
                              ? 'IVA (${ivaRate.toStringAsFixed(0)}%): ${taxAmount.toStringAsFixed(0)} COP'
                              : 'IVA no aplica',
                        ),
                      if ((offerData['tiempoEstimado']?.toString().isNotEmpty ??
                          false))
                        Text('Tiempo estimado: ${offerData['tiempoEstimado']}'),
                      if ((offerData['garantia']?.toString().isNotEmpty ??
                          false))
                        Text('Garantía: ${offerData['garantia']}'),
                      if ((offerData['paymentTerms']?.toString().isNotEmpty ??
                          false))
                        Text('Pago: ${offerData['paymentTerms']}'),
                    ],
                  ),
                ),
                Text(
                  (offerData['createdAt'] != null &&
                          offerData['createdAt'] is Timestamp)
                      ? (offerData['createdAt'] as Timestamp)
                            .toDate()
                            .toString()
                            .substring(0, 16)
                      : '',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            if (technicalSurveySheet != null) ...[
              const SizedBox(height: 14),
              TechnicalSurveySheetCard(
                sheet: technicalSurveySheet,
                providerFacing: true,
                title: 'Ficha técnica visible para tu cotización',
              ),
            ],
            if (supportAvailable) ...[
              const SizedBox(height: 14),
              SupervisorSupportCard(
                requestData: requestData!,
                providerFacing: true,
                title: 'Soporte de supervisión asociado a tu oferta',
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ProviderQuotePdfService.downloadQuotePdf(
                    offerData: offerData,
                    requestData: requestData,
                  );
                },
                icon: const Icon(Icons.download_outlined),
                label: const Text('Descargar PDF'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
