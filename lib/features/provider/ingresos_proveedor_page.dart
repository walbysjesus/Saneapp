import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class IngresosProveedorPage extends StatelessWidget {
  const IngresosProveedorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No autenticado.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Ingresos premium')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('payments')
            .where('proveedorId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No hay ingresos premium registrados.'),
            );
          }
          final pagos = snapshot.data!.docs;
          double total = 0;
          double comision = 0;
          double inCustody = 0;
          for (var doc in pagos) {
            final data = doc.data();
            final amount = (data['monto'] ?? 0).toDouble();
            if ((data['paymentStatus']?.toString() ?? '') == 'liberado') {
              total += amount;
              comision += (data['comision'] ?? 0).toDouble();
            }
            if ((data['paymentStatus']?.toString() ?? '') == 'en_custodia') {
              inCustody += amount;
            }
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total mensual:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(NumberFormat.simpleCurrency().format(total)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'En custodia SaneApp:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(NumberFormat.simpleCurrency().format(inCustody)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ComisiÃ³n descontada:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(NumberFormat.simpleCurrency().format(comision)),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.separated(
                  itemCount: pagos.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final data = pagos[index].data();
                    final status =
                        data['paymentStatus']?.toString() ?? 'pendiente';
                    return ListTile(
                      leading: Icon(
                        status == 'liberado'
                            ? Icons.attach_money
                            : status == 'en_custodia'
                            ? Icons.lock_clock_outlined
                            : Icons.gpp_maybe_outlined,
                      ),
                      title: Text(
                        '${data['requestTitle'] ?? 'Pago premium'} · ${NumberFormat.simpleCurrency().format(data['monto'] ?? 0)}',
                      ),
                      subtitle: Text(
                        'Estado: $status · Comisión: ${NumberFormat.simpleCurrency().format(data['comision'] ?? 0)}',
                      ),
                      trailing: Text(
                        (data['fecha'] != null && data['fecha'] is Timestamp)
                            ? DateFormat(
                                'dd/MM/yyyy',
                              ).format((data['fecha'] as Timestamp).toDate())
                            : '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    );
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
