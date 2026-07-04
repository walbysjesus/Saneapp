import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:saneapp_pro_nuevo/services/payment_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({
    super.key,
    required this.solicitudId,
    required this.selectedOfferId,
    required this.proveedorId,
    required this.providerName,
    required this.requestTitle,
    required this.totalAmount,
  });

  final String solicitudId;
  final String selectedOfferId;
  final String proveedorId;
  final String providerName;
  final String requestTitle;
  final double totalAmount;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const _brandGreen = Color(0xFF2E7D32);
  PaymentMethod _selectedMethod = PaymentMethod.mercadoPago;
  bool _submitting = false;

  Future<void> _confirmPremiumPayment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    setState(() => _submitting = true);
    try {
      final checkoutUrl = await PaymentService.startEscrowPayment(
        solicitudId: widget.solicitudId,
        generadorId: user.uid,
        proveedorId: widget.proveedorId,
        amount: widget.totalAmount,
        method: _selectedMethod,
        selectedOfferId: widget.selectedOfferId,
        requestTitle: widget.requestTitle,
        providerName: widget.providerName,
        description:
            'Pago premium en custodia para ${widget.requestTitle} con ${widget.providerName}',
      );

      final checkoutUri = Uri.tryParse(checkoutUrl);
      if (checkoutUri == null) {
        throw Exception('La pasarela devolvio una URL invalida.');
      }
      final launched = await launchUrl(
        checkoutUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw Exception('No fue posible abrir el checkout de la pasarela.');
      }

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Checkout iniciado. Confirma en la pasarela para acreditar la custodia.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No fue posible registrar el pago: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalAmount = widget.totalAmount.round();
    final commissionData = PaymentService.calculateCommissionAndPayout(
      totalAmount,
    );
    final commission = commissionData['commission']!;
    final payout = commissionData['payout']!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago premium en custodia'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            Text(
              'Resumen de tu negocio premium',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Solicitud: ${widget.requestTitle}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Proveedor elegido: ${widget.providerName}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Precio total: $totalAmount COP',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const Text(
                      'El dinero quedará en custodia de SaneApp hasta que el generador libere el cierre o abra una disputa.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Comisión SaneApp (10%): $commission COP',
                      style: const TextStyle(fontSize: 15, color: Colors.green),
                    ),
                    Text(
                      'Proveedor recibirá al liberar: $payout COP',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<PaymentMethod>(
              initialValue: _selectedMethod,
              decoration: const InputDecoration(
                labelText: 'Método de pago premium',
                border: OutlineInputBorder(),
              ),
              items: PaymentMethod.values
                  .map(
                    (method) => DropdownMenuItem(
                      value: method,
                      child: Text(PaymentService.labelForMethod(method)),
                    ),
                  )
                  .toList(),
              onChanged: (method) {
                if (method != null) {
                  setState(() => _selectedMethod = method);
                }
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brandGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _submitting ? null : _confirmPremiumPayment,
                child: Text(
                  _submitting
                      ? 'Creando checkout...'
                      : 'Continuar a pasarela segura',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}
