import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  static const _brandGreen = Color(0xFF0C4F31);
  static const _brandGreenSoft = Color(0xFF1E7A4B);
  static const _surface = Color(0xFFF6FAF7);

  String? _topicFromContext(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final topic = args['topic'];
      if (topic is String && topic.trim().isNotEmpty) {
        return topic;
      }
    }
    return null;
  }

  Future<void> _sendEmail(BuildContext context, String? topic) async {
    final emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'soporte@saneapp.com',
      queryParameters: {
        'subject': topic == null
            ? 'Soporte SaneApp'
            : 'Soporte SaneApp - $topic',
        'body': topic == null
            ? 'Hola, necesito ayuda con...'
            : 'Hola, necesito ayuda con el tema: $topic.\n\nContexto del caso:\n',
      },
    );
    try {
      if (!await canLaunchUrl(emailLaunchUri)) {
        throw Exception('No se pudo abrir el cliente de correo.');
      }
      await launchUrl(emailLaunchUri);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el cliente de correo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final topic = _topicFromContext(context);
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: const Text('Contactar soporte'),
        backgroundColor: _brandGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [_brandGreen, _brandGreenSoft],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Escalamiento con soporte',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  topic == null
                      ? 'Usa este canal cuando necesites seguimiento humano, validación administrativa o acompañamiento sobre un caso.'
                      : 'Prepararemos tu contacto con contexto previo para el frente: $topic.',
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
                if (topic != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      topic,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFDCE7DF)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Qué incluir en tu caso',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 10),
                Text('1. Módulo o flujo donde ocurrió la novedad.'),
                Text('2. Número de solicitud, pago o referencia si aplica.'),
                Text('3. Evidencia o descripción breve del problema.'),
                Text('4. Impacto operativo y nivel de urgencia.'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFDCE7DF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Canal principal',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Escríbenos a soporte@saneapp.com y te responderemos lo antes posible con el equipo adecuado.',
                  style: TextStyle(color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Enviar correo'),
                    onPressed: () => _sendEmail(context, topic),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('Ver preguntas frecuentes'),
                    onPressed: () => Navigator.of(context).pushNamed(
                      '/faq',
                      arguments: topic == null ? null : {'topic': topic},
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
