import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Modelo de datos para una solicitud de servicio
class ServiceRequest {
  final String id;
  final String serviceType;
  final DateTime createdAt;
  final String city;
  final RequestStatus status;
  final PaymentStatus paymentStatus;

  ServiceRequest({
    required this.id,
    required this.serviceType,
    required this.createdAt,
    required this.city,
    required this.status,
    required this.paymentStatus,
  });
}

enum RequestStatus {
  sent,
  inReview,
  quoted,
  inProgress,
  finished,
}

enum PaymentStatus {
  pending,
  inCustody,
  released,
}

/// Mock de servicio para obtener solicitudes
class ServiceRequestService {
  Future<List<ServiceRequest>> fetchUserRequests() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      ServiceRequest(
        id: 'REQ-001',
        serviceType: 'GestiÃ³n de residuos',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        city: 'BogotÃ¡',
        status: RequestStatus.quoted,
        paymentStatus: PaymentStatus.inCustody,
      ),
      ServiceRequest(
        id: 'REQ-002',
        serviceType: 'Limpieza industrial',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        city: 'MedellÃ­n',
        status: RequestStatus.finished,
        paymentStatus: PaymentStatus.released,
      ),
      ServiceRequest(
        id: 'REQ-003',
        serviceType: 'Transporte de residuos',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        city: 'Cali',
        status: RequestStatus.inProgress,
        paymentStatus: PaymentStatus.inCustody,
      ),
    ];
  }
}

/// StateNotifier para la pantalla de Mis Solicitudes
class ServiceRequestProvider extends ChangeNotifier {
  final ServiceRequestService _service;
  List<ServiceRequest> _requests = [];
  bool _loading = false;

  List<ServiceRequest> get requests => _requests;
  bool get loading => _loading;

  ServiceRequestProvider(this._service);

  Future<void> loadRequests() async {
    _loading = true;
    notifyListeners();
    _requests = await _service.fetchUserRequests();
    _loading = false;
    notifyListeners();
  }
}

/// Widget principal de "Mis Solicitudes" profesional
class MyRequestsProPage extends StatelessWidget {
  const MyRequestsProPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ServiceRequestProvider(ServiceRequestService())..loadRequests(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis Solicitudes'),
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
        body: Consumer<ServiceRequestProvider>(
          builder: (context, provider, _) {
            if (provider.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.requests.isEmpty) {
              return const Center(child: Text('No tienes solicitudes registradas.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final req = provider.requests[index];
                return _ServiceRequestCard(request: req, onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ServiceRequestDetailPage(request: req),
                    ),
                  );
                });
              },
            );
          },
        ),
      ),
    );
  }
}

/// Card profesional para cada solicitud
class _ServiceRequestCard extends StatelessWidget {
  final ServiceRequest request;
  final VoidCallback onTap;
  const _ServiceRequestCard({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.serviceType,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  _StatusBadge(status: request.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(_formatDate(request.createdAt), style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 16),
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(request.city, style: const TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _PaymentBadge(status: request.paymentStatus),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }
}

class _StatusBadge extends StatelessWidget {
  final RequestStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final data = _statusData[status]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: data.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        data.label,
        style: TextStyle(
          color: data.color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  final PaymentStatus status;
  const _PaymentBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final data = _paymentData[status]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: data.color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        data.label,
        style: TextStyle(
          color: data.color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}

const _statusData = {
  RequestStatus.sent: _StatusData('Enviada', Color(0xFF1976D2)),
  RequestStatus.inReview: _StatusData('En revisiÃ³n', Color(0xFFFFA000)),
  RequestStatus.quoted: _StatusData('Cotizada', Color(0xFF388E3C)),
  RequestStatus.inProgress: _StatusData('En ejecuciÃ³n', Color(0xFF0288D1)),
  RequestStatus.finished: _StatusData('Finalizada', Color(0xFF2E7D32)),
};

const _paymentData = {
  PaymentStatus.pending: _PaymentData('Pendiente', Color(0xFFD32F2F)),
  PaymentStatus.inCustody: _PaymentData('En custodia por SaneApp', Color(0xFF1976D2)),
  PaymentStatus.released: _PaymentData('Liberado al proveedor', Color(0xFF388E3C)),
};

class _StatusData {
  final String label;
  final Color color;
  const _StatusData(this.label, this.color);
}

class _PaymentData {
  final String label;
  final Color color;
  const _PaymentData(this.label, this.color);
}

/// Pantalla de detalle de solicitud (estructura base, lista para expandir)
class ServiceRequestDetailPage extends StatelessWidget {
  final ServiceRequest request;
  const ServiceRequestDetailPage({required this.request, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de solicitud'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(request.serviceType, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Ciudad: ${request.city}'),
            const SizedBox(height: 8),
            Text('Fecha: ${request.createdAt}'),
            const SizedBox(height: 16),
            const Text('DescripciÃ³n del servicio solicitado:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('AquÃ­ va la descripciÃ³n detallada del servicio.'),
            const SizedBox(height: 16),
            const Text('ImÃ¡genes adjuntas:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(width: 60, height: 60, color: Colors.grey[300], child: const Icon(Icons.image)),
                const SizedBox(width: 8),
                Container(width: 60, height: 60, color: Colors.grey[300], child: const Icon(Icons.image)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Historial de cambios de estado:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            // AquÃ­ irÃ­a el historial real
            Text('â€¢ Enviada â†’ En revisiÃ³n â†’ Cotizada'),
            const SizedBox(height: 24),
            Row(
              children: [
                if (request.status == RequestStatus.quoted)
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2)),
                    child: const Text('Ver cotizaciÃ³n'),
                  ),
                if (request.status == RequestStatus.finished)
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF388E3C)),
                    child: const Text('Calificar servicio'),
                  ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Chat soporte'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

