import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/payment_service.dart';
import 'payment_dispute_page.dart';

class PagosGeneradorPage extends StatelessWidget {
  const PagosGeneradorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No autenticado.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Pagos premium')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('payments')
            .where('generadorId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay pagos registrados.'));
          }
          final pagos = snapshot.data!.docs;
          final sorted = [...pagos]
            ..sort((a, b) {
              final dateA = a.data()['createdAt'];
              final dateB = b.data()['createdAt'];
              final resolvedA = dateA is Timestamp
                  ? dateA.toDate()
                  : DateTime.fromMillisecondsSinceEpoch(0);
              final resolvedB = dateB is Timestamp
                  ? dateB.toDate()
                  : DateTime.fromMillisecondsSinceEpoch(0);
              return resolvedB.compareTo(resolvedA);
            });
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final doc = sorted[index];
              final data = doc.data();
              final paymentStatus =
                  data['paymentStatus']?.toString() ?? 'pendiente';
              final amount = (data['monto'] as num?)?.toDouble() ?? 0;
              final createdAt = data['fecha'] is Timestamp
                  ? (data['fecha'] as Timestamp).toDate()
                  : null;
              final canRelease = paymentStatus == 'en_custodia';
              final canDispute = paymentStatus == 'en_custodia';

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFDCE7DF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data['requestTitle']?.toString() ?? 'Pago premium',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _PaymentStatusPill(status: paymentStatus),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Proveedor: ${data['providerName'] ?? 'Proveedor asignado'}',
                    ),
                    Text(
                      'Método: ${data['paymentMethodLabel'] ?? data['paymentMethod'] ?? '-'}',
                    ),
                    Text('Comprobante: ${data['receiptNumber'] ?? '-'}'),
                    Text('Factura: ${data['invoiceNumber'] ?? '-'}'),
                    Text('Monto: ${amount.toStringAsFixed(0)} COP'),
                    if (createdAt != null)
                      Text(
                        'Registrado: ${DateFormat('dd/MM/yyyy HH:mm').format(createdAt)}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      _paymentNarrative(paymentStatus),
                      style: const TextStyle(
                        color: Colors.black54,
                        height: 1.35,
                      ),
                    ),
                    if (canRelease || canDispute) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (canRelease)
                            FilledButton.icon(
                              onPressed: () async {
                                await PaymentService.releaseEscrowPayment(
                                  paymentId: doc.id,
                                  releasedBy: user.uid,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Pago liberado al proveedor.',
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.lock_open_outlined),
                              label: const Text('Liberar al proveedor'),
                            ),
                          if (canDispute)
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PaymentDisputePage(
                                      paymentId: doc.id,
                                      requestTitle:
                                          data['requestTitle']?.toString() ??
                                          'Pago premium',
                                      amount: amount,
                                      providerName:
                                          data['providerName']?.toString() ??
                                          'Proveedor',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.gpp_maybe_outlined),
                              label: const Text('Abrir disputa'),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PaymentStatusPill extends StatelessWidget {
  const _PaymentStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final data = switch (status) {
      'liberado' => (
        'Liberado',
        const Color(0xFFE7F4EB),
        const Color(0xFF16633D),
      ),
      'en_disputa' => (
        'En disputa',
        const Color(0xFFFFEFE7),
        const Color(0xFFC24E00),
      ),
      'en_custodia' => (
        'En custodia',
        const Color(0xFFE7F3F9),
        const Color(0xFF1C6A8C),
      ),
      _ => ('Pendiente', const Color(0xFFF2F4F7), const Color(0xFF4E5968)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: data.$2,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        data.$1,
        style: TextStyle(color: data.$3, fontWeight: FontWeight.w700),
      ),
    );
  }
}

String _paymentNarrative(String status) {
  switch (status) {
    case 'liberado':
      return 'SaneApp ya liberó el dinero al proveedor y el cierre económico quedó completado.';
    case 'en_disputa':
      return 'La custodia quedó congelada mientras SaneApp revisa el caso, la evidencia y el alcance ejecutado.';
    case 'en_custodia':
      return 'El dinero está protegido por SaneApp. Puedes liberarlo cuando valides el cierre o abrir disputa si hubo incumplimiento.';
    default:
      return 'El pago premium todavía no terminó de consolidarse.';
  }
}
