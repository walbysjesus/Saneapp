import 'package:flutter/material.dart';
import 'service_category_page.dart';

class ServiceRequestFormPage extends StatefulWidget {
  final ServiceCardData service;
  final bool isQuote;
  const ServiceRequestFormPage({required this.service, required this.isQuote, super.key});

  @override
  State<ServiceRequestFormPage> createState() => _ServiceRequestFormPageState();
}

class _ServiceRequestFormPageState extends State<ServiceRequestFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descController = TextEditingController();
  final List<String> _images = [];
  bool _sending = false;
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isQuote ? 'Solicitar cotizaciÃ³n' : 'Solicitar servicio'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: _sent
          ? _buildConfirmation()
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Describe tu necesidad:', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Ej: Necesito recolecciÃ³n de residuos peligrosos...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Adjunta imÃ¡genes (opcional):', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ..._images.map((img) => Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 60,
                              height: 60,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image),
                            )),
                        IconButton(
                          icon: const Icon(Icons.add_a_photo),
                          onPressed: () {
                            // AquÃ­ irÃ­a la lÃ³gica real de adjuntar imÃ¡genes
                            setState(() {
                              _images.add('mock');
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                        onPressed: _sending
                            ? null
                            : () async {
                                if (_formKey.currentState?.validate() ?? false) {
                                  setState(() => _sending = true);
                                  await Future.delayed(const Duration(seconds: 1));
                                  setState(() {
                                    _sending = false;
                                    _sent = true;
                                  });
                                }
                              },
                        child: _sending
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Enviar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildConfirmation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 60),
          SizedBox(height: 16),
          Text('Â¡Solicitud enviada!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('RecibirÃ¡s confirmaciÃ³n y seguimiento en tu perfil y por correo.'),
        ],
      ),
    );
  }
}

