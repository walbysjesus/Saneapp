import 'package:flutter/material.dart';

class CertificadoDisposicionFinalPage extends StatelessWidget {
  final String? serviceId;
  final String? companyId;

  const CertificadoDisposicionFinalPage({super.key, this.serviceId, this.companyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar Certificado de DisposiciÃ³n Final'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Solicita el certificado de disposiciÃ³n final a la empresa que realizÃ³ tu servicio. SaneApp gestionarÃ¡ la solicitud y te notificarÃ¡ cuando estÃ© disponible.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.business, color: Colors.green),
                title: Text(companyId != null ? 'Empresa: $companyId' : 'Empresa no especificada'),
                subtitle: Text(serviceId != null ? 'Servicio: $serviceId' : 'Servicio no especificado'),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.file_present),
                label: const Text('Solicitar Certificado'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(200, 48),
                ),
                onPressed: () {
                  // AquÃ­ irÃ­a la lÃ³gica para enviar la solicitud a la empresa vÃ­a SaneApp
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Solicitud enviada'),
                      content: const Text('Tu solicitud de certificado ha sido enviada a la empresa. RecibirÃ¡s una notificaciÃ³n cuando estÃ© disponible.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

