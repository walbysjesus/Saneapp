import 'package:flutter/material.dart';
import 'package:saneapp_pro_nuevo/features/home/paginated_requests_list.dart';
import 'package:provider/provider.dart';
import 'package:saneapp_pro_nuevo/state/app_state.dart';


/// Estados de solicitud para mostrar en la UI
const Map<String, String> requestStatusLabels = {
  'enviada': 'Enviada',
  'en_revision': 'En revisiÃ³n',
  'cotizada': 'Cotizada',
  'en_ejecucion': 'En ejecuciÃ³n',
  'finalizada': 'Finalizada',
};

class MyRequestsPage extends StatelessWidget {
  const MyRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    final clientId = user?.uid ?? '';
    if (clientId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No has iniciado sesiÃ³n')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Solicitudes')),
      body: PaginatedRequestsList(clientId: clientId),
    );
      // Assuming the PaginatedRequestsList widget is modified to include the best offer
      // and the logic for payment confirmation is handled within that widget.
      // The following code is an example of how to handle the requests.
      // This part should be integrated into the PaginatedRequestsList or similar widget.
      // The logic for displaying requests and handling offers should be implemented here.
      // Example of how to handle requests and offers:
      // final request = ServiceRequest.fromFirestore(_docs[index]);
      // final statusLabel = requestStatusLabels[request.status] ?? request.status;
      // final offer = (_docs[index].data() as Map<String, dynamic>)['bestOffer'] as Map<String, dynamic>?;
      // return Card(
      //   child: ListTile(
      //     title: Text('Servicio: ${request.serviceId}'),
      //     subtitle: Text('Estado: $statusLabel\n${request.details}'),
      //     trailing: offer != null
      //         ? ElevatedButton.icon(
      //             icon: const Icon(Icons.payment),
      //             label: const Text('Pagar y confirmar'),
      //             onPressed: () {
      //               // LÃ³gica de pago y confirmaciÃ³n
      //             },
      //           )
      //         : _buildStatusIcon(request.status),
      //     onTap: () {
      //       showDialog(
      //         context: context,
      //         builder: (_) => AlertDialog(
      //           title: Text('Detalle de solicitud'),
      //           content: offer != null
      //               ? Column(
      //                   mainAxisSize: MainAxisSize.min,
      //                   crossAxisAlignment: CrossAxisAlignment.start,
      //                   children: [
      //                     Text('Oferta seleccionada por SaneApp:'),
      //                     Text('Proveedor: ${offer['providerName'] ?? ''}'),
      //                     Text('Precio: â‚¡${offer['price'] ?? ''}'),
      //                     Text('Detalles: ${offer['details'] ?? ''}'),
      //                   ],
      //                 )
      //               : const Text('AÃºn no hay oferta seleccionada.'),
      //           actions: [
      //             if (offer != null)
      //               ElevatedButton.icon(
      //                 icon: const Icon(Icons.payment),
      //                 label: const Text('Pagar y confirmar'),
      //                 onPressed: () {
      //                   // LÃ³gica de pago y confirmaciÃ³n
      //                   Navigator.pop(context);
      //                 },
      //               ),
      //             TextButton(
      //               child: const Text('Cerrar'),
      //               onPressed: () => Navigator.pop(context),
      //             ),
      //           ],
      //         ),
      //       );
      //     },
      //   ),
      // );
  }

}


