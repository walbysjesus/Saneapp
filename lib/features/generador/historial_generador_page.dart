import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'solicitud_detalle_page.dart';

class HistorialGeneradorPage extends StatelessWidget {
  static const Color _brandGreen = Color(0xFF0C4F31);
  static const Color _brandGreenSoft = Color(0xFF1E7A4B);

  const HistorialGeneradorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No autenticado.')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        title: const Text('Historial operativo'),
        backgroundColor: _brandGreen,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('solicitudes')
            .where('generadorId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'completada')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay historial disponible.'));
          }
          final historial = [...snapshot.data!.docs]
            ..sort((a, b) {
              final aData = a.data();
              final bData = b.data();
              final aStamp =
                  (aData['completedAt'] ??
                  aData['fecha'] ??
                  aData['createdAt']);
              final bStamp =
                  (bData['completedAt'] ??
                  bData['fecha'] ??
                  bData['createdAt']);
              final aDate = aStamp is Timestamp
                  ? aStamp
                  : Timestamp.fromMillisecondsSinceEpoch(0);
              final bDate = bStamp is Timestamp
                  ? bStamp
                  : Timestamp.fromMillisecondsSinceEpoch(0);
              return bDate.compareTo(aDate);
            });

          final withActa = historial
              .where((doc) => doc.data()['actaFinal'] != null)
              .length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_brandGreen, _brandGreenSoft],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trazabilidad y cierre',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${historial.length} servicios completados',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$withActa cierres con acta final digital y evidencia disponible para auditoría operativa.',
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ...historial.map((doc) {
                final data = doc.data();
                final actaFinal = data['actaFinal'] as Map<String, dynamic>?;
                final completedStamp =
                    data['completedAt'] ?? data['fecha'] ?? data['createdAt'];
                final completedDate = completedStamp is Timestamp
                    ? completedStamp.toDate()
                    : null;
                final imageCount =
                    (actaFinal?['imagenesFinales'] as List?)?.length ?? 0;

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
                                _HistoryBadge(
                                  label:
                                      data['serviceInterest']?.toString() ??
                                      'Servicio',
                                  background: const Color(0xFFE9F3ED),
                                  foreground: _brandGreenSoft,
                                ),
                                const _HistoryBadge(
                                  label: 'Completada',
                                  background: Color(0xFFF1F5F9),
                                  foreground: Color(0xFF4E5968),
                                ),
                                if (actaFinal != null)
                                  const _HistoryBadge(
                                    label: 'Acta disponible',
                                    background: Color(0xFFE7F4EB),
                                    foreground: _brandGreenSoft,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    data['titulo']?.toString() ??
                                        'Servicio sin titulo',
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
                            _HistoryInfoRow(
                              icon: Icons.event_available_outlined,
                              label: completedDate != null
                                  ? 'Cerrada ${completedDate.toLocal().toString().substring(0, 16)}'
                                  : 'Cierre sin fecha registrada',
                            ),
                            const SizedBox(height: 8),
                            _HistoryInfoRow(
                              icon: Icons.location_on_outlined,
                              label:
                                  data['city']?.toString() ??
                                  'Ubicación no registrada',
                            ),
                            if (actaFinal != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FBF9),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFFE0EAE4),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Acta final digital',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      actaFinal['observacionesFinales']
                                                  ?.toString()
                                                  .isNotEmpty ==
                                              true
                                          ? actaFinal['observacionesFinales']
                                                .toString()
                                          : 'Sin observaciones finales registradas.',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _HistoryBadge(
                                          label:
                                              actaFinal['cumplimientoServicio'] ==
                                                  true
                                              ? 'Cumplimiento validado'
                                              : 'Cumplimiento pendiente',
                                          background:
                                              actaFinal['cumplimientoServicio'] ==
                                                  true
                                              ? const Color(0xFFE7F4EB)
                                              : const Color(0xFFFFF4E5),
                                          foreground:
                                              actaFinal['cumplimientoServicio'] ==
                                                  true
                                              ? _brandGreenSoft
                                              : const Color(0xFFC24E00),
                                        ),
                                        _HistoryBadge(
                                          label: '$imageCount evidencias',
                                          background: const Color(0xFFF1F5F9),
                                          foreground: const Color(0xFF4E5968),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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

class _HistoryBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _HistoryBadge({
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

class _HistoryInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HistoryInfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: HistorialGeneradorPage._brandGreenSoft),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.black54)),
        ),
      ],
    );
  }
}
