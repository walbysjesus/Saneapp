import 'package:flutter/material.dart';

class ProposalDialog extends StatelessWidget {
  final dynamic request;
  final String providerId;

  const ProposalDialog({super.key, required this.request, required this.providerId});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enviar CotizaciÃ³n'),
      content: const Text('AquÃ­ irÃ¡ el formulario para enviar la cotizaciÃ³n.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

