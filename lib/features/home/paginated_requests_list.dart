import 'package:saneapp_pro_nuevo/features/home/my_requests_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:saneapp_pro_nuevo/core/models/service_models.dart';
import 'package:saneapp_pro_nuevo/shared/payment_method_selector.dart';
import 'package:saneapp_pro_nuevo/features/home/my_requests_page.dart' show requestStatusLabels;

/// Widget paginado para solicitudes del cliente
class PaginatedRequestsList extends StatefulWidget {
  final String clientId;
  const PaginatedRequestsList({required this.clientId, super.key});

  @override
  State<PaginatedRequestsList> createState() => _PaginatedRequestsListState();
}

class _PaginatedRequestsListState extends State<PaginatedRequestsList> {
    // Icono de estado de la solicitud
    Widget _buildStatusIcon(String status) {
      switch (status) {
        case 'pending':
          return const Icon(Icons.hourglass_empty, color: Colors.orange);
        case 'accepted':
          return const Icon(Icons.check_circle, color: Colors.green);
        case 'rejected':
          return const Icon(Icons.cancel, color: Colors.red);
        case 'completed':
          return const Icon(Icons.verified, color: Colors.blue);
        case 'cancelled':
          return const Icon(Icons.remove_circle, color: Colors.grey);
        default:
          return const Icon(Icons.help_outline, color: Colors.black45);
      }
    }
  static const int pageSize = 10;
  final List<DocumentSnapshot> _docs = [];
  bool _hasMore = true;
  bool _loading = false;
  String? _error;
  DocumentSnapshot? _lastDoc;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchNextPage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_loading && _hasMore) {
      _fetchNextPage();
    }
  }

  Future<void> _fetchNextPage() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      Query query = FirebaseFirestore.instance
          .collection('service_requests')
          .where('clientId', isEqualTo: widget.clientId)
          .orderBy('requestedAt', descending: true)
          .limit(pageSize);
      if (_lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }
      final snap = await query.get();
      if (snap.docs.isNotEmpty) {
        _lastDoc = snap.docs.last;
        _docs.addAll(snap.docs);
      }
      if (snap.docs.length < pageSize) {
        _hasMore = false;
      }
    } catch (e) {
      _error = 'No se pudieron cargar las solicitudes. Intenta de nuevo.';
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_docs.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              onPressed: () {
                setState(() {
                  _error = null;
                  _loading = false;
                  _hasMore = true;
                  _lastDoc = null;
                  _docs.clear();
                });
                _fetchNextPage();
              },
            ),
          ],
        ),
      );
    }
    if (_docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, color: Colors.grey[400], size: 64),
            const SizedBox(height: 16),
            const Text('No tienes solicitudes aÃºn', style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      itemCount: _docs.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _docs.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final request = ServiceRequest.fromFirestore(_docs[index]);
        final statusLabel = requestStatusLabels[request.status] ?? request.status;
        final offer = (_docs[index].data() as Map<String, dynamic>)['bestOffer'] as Map<String, dynamic>?;
        return Card(
          child: ListTile(
            title: Text('Servicio: ${request.serviceId}'),
            subtitle: Text('Estado: $statusLabel\n${request.details}'),
            trailing: offer != null
                ? ElevatedButton.icon(
                    icon: const Icon(Icons.payment),
                    label: const Text('Pagar y confirmar'),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => PaymentMethodSelector(
                          amount: offer['price'] ?? 0,
                          onSelected: (method) {
                            // AquÃ­ se llama al servicio de pagos
                            // PaymentService.pay(method, amount, ...)
                          },
                        ),
                      );
                    },
                  )
                : _buildStatusIcon(request.status),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Detalle de solicitud'),
                  content: offer != null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Oferta seleccionada por SaneApp:'),
                            Text('Proveedor: ${offer['providerName'] ?? ''}'),
                            Text('Precio: â‚¡${offer['price'] ?? ''}'),
                            Text('Detalles: ${offer['details'] ?? ''}'),
                          ],
                        )
                      : const Text('AÃºn no hay oferta seleccionada.'),
                  actions: [
                    if (offer != null)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.payment),
                        label: const Text('Pagar y confirmar'),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (_) => PaymentMethodSelector(
                              amount: offer['price'] ?? 0,
                              onSelected: (method) {
                                // PaymentService.pay(method, amount, ...)
                              },
                            ),
                          );
                          Navigator.pop(context);
                        },
                      ),
                    TextButton(
                      child: const Text('Cerrar'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}


