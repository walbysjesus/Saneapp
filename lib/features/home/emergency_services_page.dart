import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EmergencyServicesPage extends StatelessWidget {
  const EmergencyServicesPage({super.key});

  static const _alert = Color(0xFFC24E00);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F3),
      appBar: AppBar(
        title: const Text('Emergencias ambientales 24/7'),
        backgroundColor: Colors.white,
        foregroundColor: _alert,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('categories').snapshots(),
        builder: (context, categorySnapshot) {
          if (categorySnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (categorySnapshot.hasError) {
            return const Center(
              child: Text('No fue posible cargar el catálogo de emergencias.'),
            );
          }
          final categories = categorySnapshot.data?.docs ?? const [];
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchEmergencySubcategories(categories),
            builder: (context, subcategorySnapshot) {
              if (subcategorySnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final emergencySubcategories =
                  subcategorySnapshot.data ?? const [];
              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                children: [
                  const _EmergencyHero(),
                  const SizedBox(height: 18),
                  const _EmergencyChecklist(),
                  const SizedBox(height: 18),
                  ...emergencySubcategories.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _EmergencyCard(
                        title:
                            item['name'] as String? ?? 'Emergencia ambiental',
                        description:
                            item['description'] as String? ??
                            'Incidente ambiental que requiere atención prioritaria.',
                        highlighted: item['isHighlighted'] == true,
                        requiresLicense: item['requiresLicense'] == true,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/crear_solicitud',
                            arguments: {
                              'serviceInterest': item['name'],
                              'requestMode': 'emergency',
                              'serviceUrgency': 'Urgente 24/7',
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchEmergencySubcategories(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> categories,
  ) async {
    final result = <Map<String, dynamic>>[];
    for (final category in categories) {
      final subcategories = await FirebaseFirestore.instance
          .collection('categories')
          .doc(category.id)
          .collection('subcategories')
          .where('isEmergencyAvailable', isEqualTo: true)
          .get();
      for (final doc in subcategories.docs) {
        final data = doc.data();
        result.add({
          'id': doc.id,
          'name': data['name'],
          'description': data['description'],
          'requiresLicense': data['requiresLicense'],
          'isHighlighted': data['isHighlighted'],
        });
      }
    }
    result.sort((a, b) {
      final highlightedA = a['isHighlighted'] == true ? 0 : 1;
      final highlightedB = b['isHighlighted'] == true ? 0 : 1;
      if (highlightedA != highlightedB) {
        return highlightedA.compareTo(highlightedB);
      }
      return (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? '');
    });
    return result;
  }
}

class _EmergencyHero extends StatelessWidget {
  const _EmergencyHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFF0C7B0)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: EmergencyServicesPage._alert,
                size: 30,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Atención ambiental crítica con publicación prioritaria',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: EmergencyServicesPage._alert,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Selecciona el tipo de incidente y te enviaremos al flujo de solicitud en modo emergencia, con urgencia alta y soporte sugerido de supervisión.',
            style: TextStyle(color: Colors.black87, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _EmergencyChecklist extends StatelessWidget {
  const _EmergencyChecklist();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0C7B0)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Antes de publicar una emergencia',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 10),
          Text('1. Ubica el punto exacto del incidente.'),
          Text('2. Describe el material o residuo comprometido.'),
          Text('3. Indica si requiere ingreso inmediato o contención.'),
          Text('4. Ten a mano un contacto operativo para la respuesta 24/7.'),
        ],
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  final String title;
  final String description;
  final bool highlighted;
  final bool requiresLicense;
  final VoidCallback onTap;

  const _EmergencyCard({
    required this.title,
    required this.description,
    required this.highlighted,
    required this.requiresLicense,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0D7C7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (highlighted) const _EmergencyBadge(label: 'Prioridad alta'),
              if (requiresLicense)
                const _EmergencyBadge(label: 'Requiere licencia'),
            ],
          ),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: EmergencyServicesPage._alert,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.flash_on_outlined),
              label: const Text('Activar solicitud de emergencia'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyBadge extends StatelessWidget {
  final String label;

  const _EmergencyBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE1D0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: EmergencyServicesPage._alert,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
