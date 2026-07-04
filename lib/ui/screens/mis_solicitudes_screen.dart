import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../models/request_model.dart';

/// Pantalla "Mis Solicitudes" corporativa, lista para producción
class MisSolicitudesScreen extends StatelessWidget {
  const MisSolicitudesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final requests = appState.requests;
    final isLoading = appState.isLoading;
    final error = appState.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Solicitudes'),
        backgroundColor: const Color(0xFF2E7D32),
        centerTitle: true,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(child: Text('Error: $error'))
                : requests.isEmpty
                    ? const Center(child: Text('No tienes solicitudes aún.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: requests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final req = requests[i];
                          return _SolicitudCard(req: req);
                        },
                      ),
      ),
    );
  }
}

/// Card de solicitud con UI corporativa y chip de estado
class _SolicitudCard extends StatelessWidget {
  final RequestModel req;
  const _SolicitudCard({required this.req});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  req.service,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                _EstadoChip(status: req.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Fecha: ${_formatDate(req.date)}',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

/// Chip de estado de solicitud, colores corporativos
class _EstadoChip extends StatelessWidget {
  final RequestStatus status;
  const _EstadoChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final data = _chipData(status);
    return Chip(
      label: Text(data['label'] as String),
      backgroundColor: data['color'] as Color,
      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    );
  }

  Map<String, Object> _chipData(RequestStatus status) {
    switch (status) {
      case RequestStatus.enviada:
        return {'label': 'Enviada', 'color': Colors.blueGrey};
      case RequestStatus.enRevision:
        return {'label': 'En revisión', 'color': Colors.orange};
      case RequestStatus.cotizada:
        return {'label': 'Cotizada', 'color': Colors.blue};
      case RequestStatus.enEjecucion:
        return {'label': 'En ejecución', 'color': Colors.green};
      case RequestStatus.finalizada:
        return {'label': 'Finalizada', 'color': Colors.grey};
    }
  }
}

