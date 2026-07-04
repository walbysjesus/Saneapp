import 'package:flutter/material.dart';
import 'package:saneapp_pro_nuevo/services/payment_service.dart';

class MetricsPage extends StatelessWidget {
  const MetricsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Demo: mÃ©tricas y reportes
    final int totalIncome = 2500000;
    final commissionData = PaymentService.calculateCommissionAndPayout(totalIncome);
    final commission = commissionData['commission']!;
    final payout = commissionData['payout']!;
    final metrics = [
      {'label': 'Servicios publicados', 'value': 12},
      {'label': 'Solicitudes recibidas', 'value': 34},
      {'label': 'Solicitudes completadas', 'value': 28},
      {'label': 'CalificaciÃ³n promedio', 'value': 4.7},
      {'label': 'Ingresos totales', 'value': '2,500,000'},
      {'label': 'ComisiÃ³n SaneApp (10%)', 'value': commission.toString()},
      {'label': 'Ingresos netos proveedor', 'value': payout.toString()},
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('MÃ©tricas y reportes'),
        backgroundColor: const Color(0xFF388E3C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          itemCount: metrics.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, i) {
            final m = metrics[i];
            return ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.green),
              title: Text(m['label']!.toString()),
              trailing: Text(m['value'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
            );
          },
        ),
      ),
    );
  }
}


