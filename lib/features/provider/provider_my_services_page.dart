import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'models/provider_service_listing.dart';
import 'provider_access_guard.dart';

class ProviderMyServicesPage extends StatelessWidget {
  const ProviderMyServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No autenticado.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis servicios'),
        actions: [
          IconButton(
            tooltip: 'Publicar servicio',
            onPressed: () => Navigator.pushNamed(context, '/provider-service-create'),
            icon: const Icon(Icons.add_business),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/provider-service-create'),
        icon: const Icon(Icons.add),
        label: const Text('Publicar servicio'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('provider_services')
            .where('providerId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ProviderOfflineView(
              title: 'No fue posible cargar tus servicios',
              message:
                  'La conexión con Firestore no está disponible. Cuando vuelva la red podrás ver y administrar tus publicaciones.',
              onRetry: () async {
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const ProviderMyServicesPage(),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                );
              },
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _EmptyServicesState(
              onCreate: () => Navigator.pushNamed(context, '/provider-service-create'),
            );
          }

          final services = docs.map(ProviderServiceListing.fromDocument).toList()
            ..sort((a, b) => (b.updatedAt ?? b.createdAt ?? DateTime(2000)).compareTo(a.updatedAt ?? a.createdAt ?? DateTime(2000)));
          final activeCount = services.where((item) => item.isActive).length;

          return Column(
            children: [
              _ServicesSummaryBar(
                total: services.length,
                active: activeCount,
                paused: services.length - activeCount,
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: services.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return _ProviderServiceCard(service: service);
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

class _ServicesSummaryBar extends StatelessWidget {
  final int total;
  final int active;
  final int paused;

  const _ServicesSummaryBar({
    required this.total,
    required this.active,
    required this.paused,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F5A35), Color(0xFF2B8A57)],
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _MetricChip(label: 'Publicados', value: total.toString()),
          _MetricChip(label: 'Activos', value: active.toString()),
          _MetricChip(label: 'Pausados', value: paused.toString()),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _ProviderServiceCard extends StatelessWidget {
  final ProviderServiceListing service;

  const _ProviderServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.green.withOpacity(0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    service.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                _ServiceStatusBadge(isActive: service.isActive),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              service.shortDescription,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaPill(icon: Icons.category, text: service.categoryName),
                _MetaPill(icon: Icons.tune, text: service.subcategoryName),
                _MetaPill(icon: Icons.public, text: service.coverage),
                _MetaPill(icon: Icons.bolt, text: service.responseTime),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'Desde ${service.priceFrom.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(service.priceType, style: const TextStyle(color: Colors.black54)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/provider-service-create',
                    arguments: {'serviceId': service.id},
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
                TextButton.icon(
                  onPressed: () => _toggleServiceStatus(context, service),
                  icon: Icon(service.isActive ? Icons.pause_circle : Icons.play_circle),
                  label: Text(service.isActive ? 'Pausar' : 'Activar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleServiceStatus(BuildContext context, ProviderServiceListing service) async {
    await FirebaseFirestore.instance.collection('provider_services').doc(service.id).update({
      'isActive': !service.isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(service.isActive ? 'Servicio pausado.' : 'Servicio activado.'),
        ),
      );
    }
  }
}

class _ServiceStatusBadge extends StatelessWidget {
  final bool isActive;

  const _ServiceStatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF0F7B46) : const Color(0xFF8C6A11);
    final background = isActive ? const Color(0xFFDDF4E6) : const Color(0xFFFFF1C9);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        isActive ? 'Activo' : 'Pausado',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2B8A57)),
          const SizedBox(width: 6),
          Text(text),
        ],
      ),
    );
  }
}

class _EmptyServicesState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyServicesState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storefront_outlined, size: 72, color: Color(0xFF2B8A57)),
              const SizedBox(height: 18),
              const Text(
                'Todavía no has publicado servicios',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Publica tu primer servicio con descripción técnica, cobertura, precio base y tiempos de respuesta para empezar a recibir oportunidades del marketplace.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Publicar primer servicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}