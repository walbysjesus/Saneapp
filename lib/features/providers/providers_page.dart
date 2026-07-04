import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/provider_commercial_reputation_service.dart';
import 'provider_detail_page.dart';

class ProvidersPage extends StatefulWidget {
  const ProvidersPage({super.key});

  @override
  State<ProvidersPage> createState() => _ProvidersPageState();
}

class _ProvidersPageState extends State<ProvidersPage> {
  static const _brandGreen = Color(0xFF0C4F31);

  String _searchQuery = '';
  String? _selectedCity;
  String? _selectedService;

  List<Map<String, dynamic>> _normalizeProviders(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final normalized = docs
        .map((doc) {
          final data = doc.data();
          final categories =
              (data['selectedCategories'] as List?)
                  ?.map((item) => item.toString())
                  .toList() ??
              const <String>[];
          return {
            'id': doc.id,
            'name': (data['companyName'] as String?)?.trim().isNotEmpty == true
                ? (data['companyName'] as String).trim()
                : 'Proveedor sin nombre',
            'city':
                (data['operationAddress'] as String?)?.trim() ??
                'Sin ubicación',
            'service': categories.isNotEmpty
                ? categories.first
                : 'Sin categoría',
            'services': categories,
            'description':
                (data['serviceArea'] as String?)?.trim() ??
                'Proveedor operativo en servicios ambientales.',
            'logoUrl': (data['logoUrl'] as String?) ?? '',
            'operationPhone': (data['operationPhone'] as String?) ?? '',
            'operationEmail': (data['operationEmail'] as String?) ?? '',
            'profileCompleted': data['profileCompleted'] == true,
            'accountStatus': (data['status'] as String?) ?? 'pending_documents',
            'ratingAverage': (data['ratingAverage'] as num?)?.toDouble() ?? 0,
            'ratingCount': (data['ratingCount'] as num?)?.toInt() ?? 0,
            'avgResponseTimeMinutes':
                (data['avgResponseTimeMinutes'] as num?)?.toDouble() ?? 0,
            'acceptanceRate': (data['acceptanceRate'] as num?)?.toDouble() ?? 0,
            'commercialScore':
                (data['commercialScore'] as num?)?.toDouble() ?? 0,
            'commercialTier': (data['commercialTier'] as String?) ?? 'D',
            'commercialTierLabel':
                (data['commercialTierLabel'] as String?) ?? 'Por consolidar',
            'completedServices':
                (data['completedServices'] as num?)?.toInt() ?? 0,
            'rutUrl': (data['rutUrl'] as String?) ?? '',
            'camaraComercioUrl': (data['camaraComercioUrl'] as String?) ?? '',
            'cedulaUrl': (data['cedulaUrl'] as String?) ?? '',
            'certificadoBancarioUrl':
                (data['certificadoBancarioUrl'] as String?) ?? '',
          };
        })
        .where((provider) {
          final search = _searchQuery.toLowerCase();
          final name = (provider['name'] as String).toLowerCase();
          final city = (provider['city'] as String).toLowerCase();
          final services = ((provider['services'] as List?) ?? const [])
              .map((item) => item.toString().toLowerCase())
              .toList();

          final matchesSearch =
              search.isEmpty ||
              name.contains(search) ||
              services.any((service) => service.contains(search));
          final matchesCity =
              _selectedCity == null ||
              city.contains(_selectedCity!.toLowerCase());
          final matchesService =
              _selectedService == null ||
              services.any(
                (service) => service.contains(_selectedService!.toLowerCase()),
              );

          return matchesSearch && matchesCity && matchesService;
        })
        .toList();

    normalized.sort((a, b) {
      final rankA = ProviderCommercialReputationService.rankingIndex(
        a,
        activeServiceCount: ((a['services'] as List?) ?? const []).length,
      );
      final rankB = ProviderCommercialReputationService.rankingIndex(
        b,
        activeServiceCount: ((b['services'] as List?) ?? const []).length,
      );
      return rankB.compareTo(rankA);
    });

    return normalized;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedores'),
        backgroundColor: const Color(0xFF388E3C),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCity,
                        decoration: const InputDecoration(
                          labelText: 'Ciudad',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'bogotá',
                            child: Text('Bogotá'),
                          ),
                          DropdownMenuItem(
                            value: 'medellín',
                            child: Text('Medellín'),
                          ),
                          DropdownMenuItem(value: 'cali', child: Text('Cali')),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedCity = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Servicio',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (value) => setState(
                          () => _selectedService = value.trim().isEmpty
                              ? null
                              : value.trim(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Buscar por nombre',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                        ),
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.clear),
                      label: const Text('Limpiar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedCity = null;
                          _selectedService = null;
                          _searchQuery = '';
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('providers')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error cargando proveedores: ${snapshot.error}',
                    ),
                  );
                }

                final providers = _normalizeProviders(
                  snapshot.data?.docs ?? const [],
                );
                if (providers.isEmpty) {
                  return const Center(
                    child: Text(
                      'No se encontraron proveedores con los filtros seleccionados.',
                      style: TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: providers.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final provider = providers[index];
                    return _ProviderRankingTile(
                      provider: provider,
                      rankIndex: index,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ProviderDetailPage(provider: provider),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderRankingTile extends StatelessWidget {
  const _ProviderRankingTile({
    required this.provider,
    required this.rankIndex,
    required this.onTap,
  });

  final Map<String, dynamic> provider;
  final int rankIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final logoUrl = provider['logoUrl'] as String? ?? '';
    final services = ((provider['services'] as List?) ?? const [])
        .map((item) => item.toString())
        .toList();
    final reputation = ProviderCommercialReputationService.fromProviderData(
      provider,
      activeServiceCount: services.length,
    );
    final badge = ProviderCommercialReputationService.rankingBadge(
      snapshot: reputation,
      index: rankIndex,
    );
    final badgeColor = rankIndex == 0
        ? const Color(0xFFEAF4EC)
        : const Color(0xFFF4F7F5);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFDDE7E0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _ProvidersPageState._brandGreen,
                    backgroundImage: logoUrl.isNotEmpty
                        ? NetworkImage(logoUrl)
                        : null,
                    child: logoUrl.isEmpty
                        ? const Icon(Icons.business, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider['name'] as String? ?? 'Proveedor',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${provider['city']} • ${provider['service']}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFD8E4DB)),
                    ),
                    child: Text(
                      '#${rankIndex + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: rankIndex == 0
                        ? _ProvidersPageState._brandGreen
                        : Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _RankingPill(
                    icon: Icons.workspace_premium_outlined,
                    label: 'Tier ${reputation.tier}',
                  ),
                  _RankingPill(
                    icon: Icons.analytics_outlined,
                    label: '${reputation.formattedScore}/100',
                  ),
                  _RankingPill(
                    icon: Icons.bolt_outlined,
                    label: reputation.responseLabel,
                  ),
                  _RankingPill(
                    icon: Icons.assignment_turned_in_outlined,
                    label:
                        '${reputation.acceptanceRate.toStringAsFixed(0)}% aceptación',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankingPill extends StatelessWidget {
  const _RankingPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _ProvidersPageState._brandGreen),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}
