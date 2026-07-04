import 'package:flutter/material.dart';

/// Selector de mÃ©todo de pago para SaneApp
class PaymentMethodSelector extends StatelessWidget {
  final double amount;
  final void Function(String method) onSelected;

  const PaymentMethodSelector({
    super.key,
    required this.amount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selecciona un mÃ©todo de pago', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text('Tarjeta de crÃ©dito/dÃ©bito'),
            onTap: () => onSelected('card'),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('PSE / Transferencia'),
            onTap: () => onSelected('pse'),
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Efectivo'),
            onTap: () => onSelected('cash'),
          ),
          const SizedBox(height: 16),
          Text('Total a pagar: â‚¡${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

