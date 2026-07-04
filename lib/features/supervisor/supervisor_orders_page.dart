import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'supervisor_acta_page.dart';
import 'supervisor_supervision_workbench_page.dart';

class SupervisorOrdersPage extends StatefulWidget {
  const SupervisorOrdersPage({super.key});

  @override
  State<SupervisorOrdersPage> createState() => _SupervisorOrdersPageState();
}

enum _SupervisorOrderFilter {
  all,
  verification,
  accompaniment,
  closure,
  incidents,
}

class _SupervisorOrdersPageState extends State<SupervisorOrdersPage> {
  _SupervisorOrderFilter _filter = _SupervisorOrderFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const _brandGreen = Color(0xFF0C4F31);
  static const _surface = Color(0xFFF6FAF7);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No autenticado.')));
    }

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: const Text('Órdenes operativas'),
        backgroundColor: _brandGreen,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('solicitudes')
            .where('supervisorId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? const [];
          final filtered = docs.where(_matchesFilter).where(_matchesSearch).toList()
            ..sort((a, b) {
              final urgencyA = a.data()['serviceUrgency']?.toString() ?? '';
              final urgencyB = b.data()['serviceUrgency']?.toString() ?? '';
              return _priorityWeight(urgencyB).compareTo(_priorityWeight(urgencyA));
            });

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar por numero de orden o servicio',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              _FilterBar(
                selected: _filter,
                onSelected: (value) => setState(() => _filter = value),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                const _OrdersEmptyState()
              else
                ...filtered.map((doc) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OrderCard(solicitud: doc),
                    )),
            ],
          );
        },
      ),
    );
  }

  bool _matchesFilter(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final status = data['supervisorStatus']?.toString() ?? 'pendiente_verificacion';
    final incidentCount = _incidentCount(data);
    switch (_filter) {
      case _SupervisorOrderFilter.all:
        return true;
      case _SupervisorOrderFilter.verification:
        return status == 'pendiente_verificacion';
      case _SupervisorOrderFilter.accompaniment:
        return status == 'en_acompanamiento';
      case _SupervisorOrderFilter.closure:
        return status == 'verificado' || status == 'en_acompanamiento';
      case _SupervisorOrderFilter.incidents:
        return incidentCount > 0;
    }
  }

  bool _matchesSearch(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }
    final data = doc.data();
    final orderCode = data['supervisorOrderCode']?.toString() ?? '';
    final title = data['titulo']?.toString() ?? data['service']?.toString() ?? '';
    return '$orderCode $title'.toLowerCase().contains(query);
  }

  int _incidentCount(Map<String, dynamic> data) {
    final evaluation = data['providerQualityEvaluation'];
    if (evaluation is Map<String, dynamic>) {
      return (evaluation['incidentCount'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  int _priorityWeight(String urgency) {
    final normalized = urgency.toLowerCase();
    if (normalized.contains('urgente') || normalized.contains('alta')) {
      return 3;
    }
    if (normalized.contains('media')) {
      return 2;
    }
    return 1;
  }
}

class _FilterBar extends StatelessWidget {
  final _SupervisorOrderFilter selected;
  final ValueChanged<_SupervisorOrderFilter> onSelected;

  const _FilterBar({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChipItem(label: 'Todas', value: _SupervisorOrderFilter.all, selected: selected, onSelected: onSelected),
        _FilterChipItem(label: 'Verificación', value: _SupervisorOrderFilter.verification, selected: selected, onSelected: onSelected),
        _FilterChipItem(label: 'Acompañamiento', value: _SupervisorOrderFilter.accompaniment, selected: selected, onSelected: onSelected),
        _FilterChipItem(label: 'Cierre', value: _SupervisorOrderFilter.closure, selected: selected, onSelected: onSelected),
        _FilterChipItem(label: 'Incidencias', value: _SupervisorOrderFilter.incidents, selected: selected, onSelected: onSelected),
      ],
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final _SupervisorOrderFilter value;
  final _SupervisorOrderFilter selected;
  final ValueChanged<_SupervisorOrderFilter> onSelected;

  const _FilterChipItem({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> solicitud;

  const _OrderCard({required this.solicitud});

  @override
  Widget build(BuildContext context) {
    final data = solicitud.data();
    final title = data['titulo']?.toString() ?? data['service']?.toString() ?? 'Servicio ambiental';
    final status = data['supervisorStatus']?.toString() ?? 'pendiente_verificacion';
    final city = data['city']?.toString() ?? data['ubicacion']?.toString() ?? 'Sin ciudad';
    final generator = data['generadorNombre']?.toString() ?? 'Generador';
    final orderCode = data['supervisorOrderCode']?.toString();
    final urgency = data['serviceUrgency']?.toString() ?? 'Operativa';
    final incidentCount = _incidentCount(data);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCE7DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 6),
          if (orderCode != null && orderCode.isNotEmpty)
            Text(
              'Orden: $orderCode',
              style: const TextStyle(color: Color(0xFF0C4F31), fontWeight: FontWeight.w700),
            ),
          if (orderCode != null && orderCode.isNotEmpty)
            const SizedBox(height: 4),
          if (orderCode != null && orderCode.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: orderCode));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Numero de orden copiado.')),
                    );
                  }
                },
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copiar orden'),
              ),
            ),
          Text('Generador: $generator', style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(label: _mapStatus(status)),
              _Pill(label: city),
              _Pill(label: urgency),
              if (incidentCount > 0) _Pill(label: '$incidentCount incidencias'),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SupervisorSupervisionWorkbenchPage(solicitudId: solicitud.id),
                  ),
                ),
                icon: const Icon(Icons.edit_note_outlined),
                label: const Text('Workbench'),
              ),
              if (status == 'pendiente_verificacion')
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SupervisorActaPage(solicitudId: solicitud.id, esActaFinal: false),
                    ),
                  ),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Acta inicial'),
                ),
              if (status == 'en_acompanamiento' || status == 'verificado')
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SupervisorActaPage(solicitudId: solicitud.id, esActaFinal: true),
                    ),
                  ),
                  icon: const Icon(Icons.assignment_turned_in_outlined),
                  label: const Text('Acta final'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  int _incidentCount(Map<String, dynamic> data) {
    final evaluation = data['providerQualityEvaluation'];
    if (evaluation is Map<String, dynamic>) {
      return (evaluation['incidentCount'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  String _mapStatus(String value) {
    switch (value) {
      case 'pendiente_verificacion':
        return 'Verificación inicial';
      case 'verificado':
        return 'Verificado';
      case 'en_acompanamiento':
        return 'Acompañamiento';
      case 'finalizado':
        return 'Finalizado';
      default:
        return value;
    }
  }
}

class _Pill extends StatelessWidget {
  final String label;

  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6F3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _OrdersEmptyState extends StatelessWidget {
  const _OrdersEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCE7DF)),
      ),
      child: const Column(
        children: [
          Icon(Icons.assignment_late_outlined, size: 42, color: Colors.black38),
          SizedBox(height: 10),
          Text('No hay órdenes para este filtro.', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text('Cuando lleguen nuevas visitas o cierres operativos aparecerán aquí.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
