import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/payment_service.dart';

class PaymentDisputePage extends StatefulWidget {
  const PaymentDisputePage({
    super.key,
    required this.paymentId,
    required this.requestTitle,
    required this.amount,
    required this.providerName,
  });

  final String paymentId;
  final String requestTitle;
  final double amount;
  final String providerName;

  @override
  State<PaymentDisputePage> createState() => _PaymentDisputePageState();
}

class _PaymentDisputePageState extends State<PaymentDisputePage> {
  static const _brandGreen = Color(0xFF0C4F31);

  final _detailsController = TextEditingController();
  final _evidenceController = TextEditingController();
  String _reason = 'Incumplimiento del alcance';
  bool _submitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    if (_detailsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Describe el motivo de la disputa.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await PaymentService.openDispute(
        paymentId: widget.paymentId,
        openedBy: user.uid,
        reason: _reason,
        details: _detailsController.text.trim(),
        evidenceNote: _evidenceController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disputa abierta correctamente.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No fue posible abrir la disputa: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Abrir disputa premium'),
        backgroundColor: _brandGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FBF8),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFDCE7DF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Caso a revisar por SaneApp',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(widget.requestTitle),
                const SizedBox(height: 4),
                Text('Proveedor: ${widget.providerName}'),
                const SizedBox(height: 4),
                Text(
                  'Monto en custodia: ${widget.amount.toStringAsFixed(0)} COP',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: _reason,
            decoration: const InputDecoration(
              labelText: 'Motivo principal',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Incumplimiento del alcance',
                child: Text('Incumplimiento del alcance'),
              ),
              DropdownMenuItem(
                value: 'Calidad inferior a la acordada',
                child: Text('Calidad inferior a la acordada'),
              ),
              DropdownMenuItem(
                value: 'Diferencia entre oferta y ejecución',
                child: Text('Diferencia entre oferta y ejecución'),
              ),
              DropdownMenuItem(
                value: 'Otro conflicto comercial',
                child: Text('Otro conflicto comercial'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _reason = value);
              }
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _detailsController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Describe el caso',
              hintText:
                  'Explica qué salió mal, qué esperabas y qué necesita revisar SaneApp.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _evidenceController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Evidencia o referencias',
              hintText:
                  'Adjunta notas sobre actas, fotos, correos o entregables relacionados.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: _brandGreen,
              foregroundColor: Colors.white,
            ),
            icon: _submitting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.gpp_maybe_outlined),
            label: const Text('Abrir disputa'),
          ),
        ],
      ),
    );
  }
}
