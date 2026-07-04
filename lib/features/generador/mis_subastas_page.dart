import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../shared/request_image_gallery.dart';
import 'solicitud_detalle_page.dart';

class MisSubastasPage extends StatelessWidget {
  static const Color _brandGreen = Color(0xFF0C4F31);
  static const Color _brandGreenSoft = Color(0xFF1E7A4B);

  const MisSubastasPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No autenticado.')));
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        title: const Text('Mis subastas activas'),
        backgroundColor: Colors.transparent,
        foregroundColor: _brandGreen,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('solicitudes')
            .where('generadorId', isEqualTo: user.uid)
            .where('type', isEqualTo: 'subasta')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No tienes subastas creadas.'));
          }
          final subastas = snapshot.data!.docs
            ..sort((a, b) {
              final aDate = (a.data() as Map<String, dynamic>)['createdAt'];
              final bDate = (b.data() as Map<String, dynamic>)['createdAt'];
              final aTs = aDate is Timestamp ? aDate : Timestamp(0, 0);
              final bTs = bDate is Timestamp ? bDate : Timestamp(0, 0);
              return bTs.compareTo(aTs);
            });

          final openCount = subastas.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status']?.toString().toLowerCase() ?? '';
            return status.isEmpty || status == 'abierta' || status == 'pending';
          }).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Compite por mejores condiciones',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${subastas.length} subastas publicadas',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$openCount abiertas para recibir propuestas y negociar mejores tiempos, precio y cobertura.',
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ...subastas.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final deadline = data['deadline'];
                final deadlineText = deadline is Timestamp
                    ? deadline.toDate().toString().substring(0, 16)
                    : 'Sin cierre definido';
                final budget =
                  (data['budgetReference'] as num?)?.toDouble() ??
                  (data['referenceBudget'] as num?)?.toDouble() ??
                  0;
                final category =
                    data['serviceCategory']?.toString() ??
                    data['serviceInterest']?.toString() ??
                    'Subasta';
                final status = data['status']?.toString() ?? 'abierta';
                final requestImages =
                  (data['requestImageUrls'] as List?)?.cast<String>() ??
                  const [];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SolicitudDetallePage(solicitudId: doc.id),
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
                                _Badge(
                                  label: category,
                                  background: const Color(0xFFE9F3ED),
                                  foreground: _brandGreenSoft,
                                ),
                                _Badge(
                                  label: status,
                                  background: const Color(0xFFF2F4F7),
                                  foreground: const Color(0xFF4E5968),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    data['titulo']?.toString() ??
                                        'Subasta sin titulo',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Colors.black38,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              data['descripcion']?.toString() ?? '',
                              style: const TextStyle(
                                color: Colors.black54,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _InfoItem(
                                    icon: Icons.payments_outlined,
                                    label: budget > 0
                                        ? '${budget.toStringAsFixed(0)} COP'
                                        : 'Sin presupuesto guía',
                                  ),
                                ),
                                Expanded(
                                  child: _InfoItem(
                                    icon: Icons.event_outlined,
                                    label: deadlineText,
                                  ),
                                ),
                              ],
                            ),
                            if (requestImages.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              RequestImageGallery(
                                imageUrls: requestImages,
                                title: 'Adjuntos de la subasta',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
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
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: MisSubastasPage._brandGreenSoft),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
