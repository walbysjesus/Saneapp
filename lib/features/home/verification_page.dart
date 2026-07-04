import 'package:flutter/material.dart';

class VerificationPage extends StatelessWidget {
  const VerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VerificaciÃ³n y certificaciÃ³n de empresa'),
        backgroundColor: const Color(0xFF388E3C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Solicita la verificaciÃ³n y certificaciÃ³n de tu empresa para aumentar la confianza de tus clientes.', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.verified, color: Colors.green),
                title: const Text('Solicitar verificaciÃ³n'),
                subtitle: const Text('EnvÃ­a tus documentos y datos para revisiÃ³n.'),
                onTap: () {
                  // AquÃ­ irÃ­a el flujo real de solicitud y carga de documentos
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Solicitud enviada (demo)')),
                  );
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.info, color: Colors.green),
                title: const Text('Â¿CÃ³mo funciona?'),
                subtitle: const Text('Nuestro equipo revisarÃ¡ tus datos y te notificarÃ¡ el resultado.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

