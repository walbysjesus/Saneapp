import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../home/payment_page.dart';
import 'solicitud_detalle_page.dart';

class OfertasRecibidasPage extends StatelessWidget {
  const OfertasRecibidasPage({super.key});

  static const _brandGreen = Color(0xFF0C4F31);
  static const _brandGreenSoft = Color(0xFF1E7A4B);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No autenticado.')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      appBar: AppBar(
        title: const Text('Ofertas recibidas'),
        backgroundColor: _brandGreen,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('solicitudes')
            .where('generadorId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final requests = snapshot.data?.docs ?? const [];
          if (requests.isEmpty) {
            return const _EmptyOffersState();
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const _OffersHero(),
              const SizedBox(height: 16),
              ...requests.map(
                (request) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _OffersComparisonCard(
                    requestId: request.id,
                    requestData: request.data(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OffersHero extends StatelessWidget {
  const _OffersHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [
            OfertasRecibidasPage._brandGreen,
            OfertasRecibidasPage._brandGreenSoft,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compara ofertas como en un marketplace B2B',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Revisa precio, tiempo, garantía y costo total antes de adjudicar. Desde aquí puedes entrar al detalle completo de cada solicitud.',
            style: TextStyle(color: Colors.white70, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _OffersComparisonCard extends StatelessWidget {
  final String requestId;
  final Map<String, dynamic> requestData;

  const _OffersComparisonCard({
    required this.requestId,
    required this.requestData,
  });

  @override
  Widget build(BuildContext context) {
    final supervisorRequested = requestData['supervisorRequested'] == true;
    final supervisorCost =
        (requestData['supervisorCost'] as num?)?.toDouble() ?? 0;
    final isEmergency = requestData['type'] == 'emergency';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
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
              _OfferBadge(
                label:
                    requestData['serviceInterest']?.toString() ??
                    'Sin categoría',
                background: const Color(0xFFE9F3ED),
                foreground: OfertasRecibidasPage._brandGreenSoft,
              ),
              _OfferBadge(
                label: requestData['status']?.toString() ?? 'Sin estado',
                background: const Color(0xFFF2F4F7),
                foreground: const Color(0xFF526070),
              ),
              if (isEmergency)
                const _OfferBadge(
                  label: 'Emergencia',
                  background: Color(0xFFFFE1D0),
                  foreground: Color(0xFFC24E00),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            requestData['titulo']?.toString() ?? 'Solicitud',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            requestData['descripcion']?.toString() ?? '',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('ofertas')
                .where('solicitudId', isEqualTo: requestId)
                .snapshots(),
            builder: (context, snapshot) {
              final offers = snapshot.data?.docs ?? const [];
              if (offers.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aún no has recibido ofertas para esta publicación.',
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SolicitudDetallePage(solicitudId: requestId),
                            ),
                          );
                        },
                        child: const Text('Ver detalle'),
                      ),
                    ),
                  ],
                );
              }

              final sortedOffers = [...offers]
                ..sort((a, b) {
                  final priceA = (a.data()['price'] as num?)?.toDouble() ?? 0;
                  final priceB = (b.data()['price'] as num?)?.toDouble() ?? 0;
                  return priceA.compareTo(priceB);
                });
              final bestOffer = sortedOffers.first.data();
              final bestTotal =
                  ((bestOffer['price'] as num?)?.toDouble() ?? 0) +
                  (supervisorRequested ? supervisorCost : 0);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MiniMetric(
                          label: 'Ofertas',
                          value: '${sortedOffers.length}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniMetric(
                          label: 'Mejor total',
                          value: '${bestTotal.toStringAsFixed(0)} COP',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...sortedOffers.take(3).map((offerDoc) {
                    final offer = offerDoc.data();
                    final price = (offer['price'] as num?)?.toDouble() ?? 0;
                    final total =
                        price + (supervisorRequested ? supervisorCost : 0);
                    final rating =
                        (offer['calificacionProveedor'] as num?)?.toDouble() ??
                        0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FBFA),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2EAE4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Proveedor ${offer['proveedorId']?.toString().substring(0, 6) ?? '-'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (identical(offerDoc, sortedOffers.first))
                                const _OfferBadge(
                                  label: 'Mejor opción',
                                  background: Color(0xFFE7F4EB),
                                  foreground:
                                      OfertasRecibidasPage._brandGreenSoft,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Precio: ${price.toStringAsFixed(0)} COP'),
                          Text(
                            'Tiempo estimado: ${offer['tiempoEstimado'] ?? '-'}',
                          ),
                          Text('Garantía: ${offer['garantia'] ?? '-'}'),
                          Text(
                            'Calificación: ${rating > 0 ? rating.toStringAsFixed(1) : '-'}',
                          ),
                          if (supervisorRequested)
                            Text(
                              'Total con supervisión: ${total.toStringAsFixed(0)} COP',
                            ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SolicitudDetallePage(
                                          solicitudId: requestId,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('Ver detalle'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final confirmed =
                                        await Navigator.push<bool>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PaymentPage(
                                              solicitudId: requestId,
                                              selectedOfferId: offerDoc.id,
                                              proveedorId:
                                                  offer['proveedorId']
                                                      ?.toString() ??
                                                  '',
                                              providerName:
                                                  offer['providerName']
                                                      ?.toString() ??
                                                  'Proveedor seleccionado',
                                              requestTitle:
                                                  requestData['titulo']
                                                      ?.toString() ??
                                                  'Solicitud ambiental',
                                              totalAmount: total,
                                            ),
                                          ),
                                        );
                                    if (confirmed == true && context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Oferta aceptada y pago puesto en custodia premium.',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        OfertasRecibidasPage._brandGreen,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Aceptar y pagar'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _OfferBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _OfferBadge({
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

class _EmptyOffersState extends StatelessWidget {
  const _EmptyOffersState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 48,
              color: OfertasRecibidasPage._brandGreenSoft,
            ),
            const SizedBox(height: 14),
            const Text(
              'Aún no tienes publicaciones para comparar ofertas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea una solicitud o subasta para empezar a recibir propuestas de proveedores.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/crear_solicitud'),
              style: ElevatedButton.styleFrom(
                backgroundColor: OfertasRecibidasPage._brandGreen,
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
