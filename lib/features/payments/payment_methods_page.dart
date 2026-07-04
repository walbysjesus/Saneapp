import 'package:flutter/material.dart';

class PaymentMethodsPage extends StatelessWidget {
  final double amount;
  const PaymentMethodsPage({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    final methods = [
      {'name': 'PayPal', 'icon': Icons.account_balance_wallet},
      {'name': 'MercadoPago', 'icon': Icons.payment},
      {'name': 'PayU', 'icon': Icons.credit_card},
      {'name': 'Nequi', 'icon': Icons.phone_android},
      {'name': 'Daviplata', 'icon': Icons.phone_iphone},
      {'name': 'PSE', 'icon': Icons.account_balance},
      {'name': 'Tarjeta de crÃ©dito/dÃ©bito', 'icon': Icons.credit_card},
      {'name': 'Efecty', 'icon': Icons.store},
      {'name': 'Baloto', 'icon': Icons.storefront},
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona mÃ©todo de pago'),
        backgroundColor: const Color(0xFF388E3C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total a pagar: \u20b1${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: methods.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, i) {
                  final m = methods[i];
                  return ListTile(
                    leading: Icon(m['icon'] as IconData, color: Colors.green[700]),
                    title: Text(m['name'] as String),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // AquÃ­ irÃ­a la integraciÃ³n real con el mÃ©todo de pago
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Pago con ${m['name']} no implementado (demo)')),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text('Estado del pago: Pendiente', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

