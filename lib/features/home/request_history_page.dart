import 'package:flutter/material.dart';

class RequestHistoryPage extends StatelessWidget {
  const RequestHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Demo: historial de solicitudes
    final requests = [
      {'id': 'REQ-001', 'service': 'Reciclaje', 'date': '2026-01-30', 'status': 'En proceso'},
      {'id': 'REQ-002', 'service': 'Aceites usados', 'date': '2026-01-28', 'status': 'Completado'},
      {'id': 'REQ-003', 'service': 'Limpieza industrial', 'date': '2026-01-25', 'status': 'Pendiente'},
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de solicitudes'),
        backgroundColor: const Color(0xFF388E3C),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, i) {
          final r = requests[i];
          return ListTile(
            leading: const Icon(Icons.assignment, color: Colors.green),
            title: Text(r['service']!),
            subtitle: Text('Fecha: ${r['date']}'),
            trailing: Text(r['status']!, style: TextStyle(color: r['status'] == 'Completado' ? Colors.green : Colors.orange)),
            onTap: () {
              // AquÃ­ podrÃ­as mostrar el detalle y seguimiento de la solicitud
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Detalle de ${r['id']}'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Servicio: ${r['service']}'),
                      Text('Fecha: ${r['date']}'),
                      Text('Estado: ${r['status']}'),
                      const SizedBox(height: 12),
                      // Demo: monto y desglose
                      Text('Monto total: \$300,000 COP'),
                      Text('ComisiÃ³n SaneApp (10%): \$30,000 COP', style: TextStyle(color: Colors.green)),
                      Text('Proveedor recibe: \$270,000 COP', style: TextStyle(color: Colors.blueGrey)),
                    ],
                  ),
                  actions: [TextButton(child: const Text('Cerrar'), onPressed: () => Navigator.pop(ctx))],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

