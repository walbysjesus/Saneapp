import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../ui/widgets/corporate_button.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

/// Panel de administraciÃ³n para usuarios con rol admin.
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de Administración')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _AdminCommercialMonitor(),
              const SizedBox(height: 16),
              CorporateButton(
                text: 'Aprobar/Rechazar Perfiles',
                icon: Icons.verified_user,
                onPressed: () =>
                    Navigator.pushNamed(context, '/admin-approval'),
              ),
              const SizedBox(height: 12),
              CorporateButton(
                text: 'Gestión de Roles',
                icon: Icons.people,
                onPressed: () =>
                    Navigator.pushNamed(context, '/admin-manage-roles'),
              ),
              const SizedBox(height: 12),
              CorporateButton(
                text: 'Ver Solicitudes y Subastas',
                icon: Icons.assignment,
                onPressed: () =>
                    Navigator.pushNamed(context, '/admin-requests'),
              ),
              const SizedBox(height: 12),
              CorporateButton(
                text: 'Logs de Actividad',
                icon: Icons.history,
                onPressed: () => Navigator.pushNamed(context, '/admin-logs'),
              ),
              const SizedBox(height: 12),
              CorporateButton(
                text: 'Configuraciones Avanzadas',
                icon: Icons.settings,
                onPressed: () =>
                    Navigator.pushNamed(context, '/admin-settings'),
              ),
              const SizedBox(height: 12),
              CorporateButton(
                text: 'Reportes',
                icon: Icons.bar_chart,
                onPressed: () => Navigator.pushNamed(context, '/admin-reports'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminCommercialMonitor extends StatelessWidget {
  const _AdminCommercialMonitor();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('solicitudes').snapshots(),
      builder: (context, requestSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('billing_records')
              .snapshots(),
          builder: (context, billingSnapshot) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collectionGroup('policy_events')
                  .snapshots(),
              builder: (context, policySnapshot) {
                final requestDocs = requestSnapshot.data?.docs ?? const [];
                final billingDocs = billingSnapshot.data?.docs ?? const [];
                final policyDocs = policySnapshot.data?.docs ?? const [];
                final visibleClientDocs = billingDocs.where((doc) {
                  return doc.data()['visibleToClient'] == true;
                }).length;
                final providerSupportDocs = billingDocs.where((doc) {
                  return (doc.data()['documentType']?.toString() ?? '') ==
                      'provider_support_document';
                }).length;
                final blockedAttempts = policyDocs.length;
                final releasedDocs = billingDocs.where((doc) {
                  final data = doc.data();
                  return data['visibleToClient'] == true &&
                      data['status']?.toString() == 'liberado';
                }).toList();
                final gmvReleased = releasedDocs.fold<double>(0, (sum, doc) {
                  return sum +
                      ((doc.data()['amount'] as num?)?.toDouble() ?? 0);
                });
                final categorySummary = <String, int>{};
                final subcategorySummary = <String, int>{};
                for (final requestDoc in requestDocs) {
                  final data = requestDoc.data();
                  final category =
                      data['serviceCategory']?.toString() ??
                      data['serviceInterest']?.toString() ??
                      'Sin categoría';
                  final subcategory =
                      data['serviceSubcategory']?.toString() ?? '';
                  categorySummary.update(
                    category,
                    (count) => count + 1,
                    ifAbsent: () => 1,
                  );
                  if (subcategory.trim().isNotEmpty &&
                      subcategory != 'Sin subcategoría definida') {
                    final key = '$category · $subcategory';
                    subcategorySummary.update(
                      key,
                      (count) => count + 1,
                      ifAbsent: () => 1,
                    );
                  }
                }
                final topCategories = categorySummary.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                final topSubcategories = subcategorySummary.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                final recentPolicyDocs = policyDocs.toList()
                  ..sort((a, b) {
                    final aDate =
                        (a.data()['createdAt'] as Timestamp?)?.toDate() ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    final bDate =
                        (b.data()['createdAt'] as Timestamp?)?.toDate() ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    return bDate.compareTo(aDate);
                  });

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFDCE7DF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monitoreo comercial',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _AdminMetric(
                            label: 'Docs cliente',
                            value: '$visibleClientDocs',
                          ),
                          _AdminMetric(
                            label: 'Soportes proveedor',
                            value: '$providerSupportDocs',
                          ),
                          _AdminMetric(
                            label: 'Intentos bloqueados',
                            value: '$blockedAttempts',
                          ),
                          _AdminMetric(
                            label: 'Expedientes',
                            value: '${requestDocs.length}',
                          ),
                          _AdminMetric(
                            label: 'GMV liberado',
                            value: gmvReleased.toStringAsFixed(0),
                          ),
                        ],
                      ),
                      if (topCategories.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Text(
                          'Demanda por categoría',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        ...topCategories
                            .take(4)
                            .map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  '• ${entry.key} · ${entry.value} expedientes',
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ),
                            ),
                      ],
                      if (topSubcategories.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Text(
                          'Subcategorías con mayor tracción',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        ...topSubcategories
                            .take(4)
                            .map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  '• ${entry.key} · ${entry.value} expedientes',
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ),
                            ),
                      ],
                      if (recentPolicyDocs.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Text(
                          'Eventos recientes de desintermediación',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        ...recentPolicyDocs.take(5).map((doc) {
                          final data = doc.data();
                          final reasons =
                              ((data['reasons'] as List?) ?? const [])
                                  .map((item) => item.toString())
                                  .join(', ');
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '• ${data['requestTitle'] ?? 'Solicitud'} · ${data['senderRole'] ?? 'actor'} · $reasons',
                              style: const TextStyle(color: Colors.black87),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _AdminMetric extends StatelessWidget {
  const _AdminMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE7DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
