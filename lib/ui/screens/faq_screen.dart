import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

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

  List<_FaqItem> _itemsForTopic(String? topic) {
    switch (topic) {
      case 'Cuenta y perfil':
        return const [
          _FaqItem(
            question: '¿Cómo actualizo los datos de mi perfil?',
            answer:
                'Ingresa a Perfil cliente, edita los datos principales y guarda los cambios para mantener tu cuenta alineada con la operación actual.',
          ),
          _FaqItem(
            question: '¿Qué hago si no puedo acceder a mi cuenta?',
            answer:
                'Primero verifica correo y contraseña. Si el acceso sigue bloqueado, usa contacto soporte para validar identidad y restablecer acceso.',
          ),
          _FaqItem(
            question: '¿Cómo verifico el estado de mi cuenta?',
            answer:
                'Revisa la información del perfil y los módulos de verificación. Si algo luce inconsistente, escala el caso a soporte.',
          ),
        ];
      case 'Solicitudes, subastas y ofertas':
        return const [
          _FaqItem(
            question: '¿Dónde veo mis solicitudes activas?',
            answer:
                'Desde el módulo Mis solicitudes puedes revisar estado, avances, adjudicación y trazabilidad operativa.',
          ),
          _FaqItem(
            question: '¿Qué hago si una oferta no aparece o no carga?',
            answer:
                'Verifica conexión y vuelve a entrar al módulo. Si el problema persiste, usa chat o contacto soporte con el nombre de la solicitud.',
          ),
          _FaqItem(
            question: '¿Cómo publico un requerimiento con mejor detalle?',
            answer:
                'Incluye alcance, urgencia, ubicación y evidencias. Eso reduce reprocesos y mejora la calidad de las propuestas.',
          ),
        ];
      case 'Pagos y facturación':
        return const [
          _FaqItem(
            question: '¿Dónde reviso el estado de un pago?',
            answer:
                'En el módulo de pagos podrás consultar movimientos, estados y soporte administrativo asociado a cada cobro.',
          ),
          _FaqItem(
            question: '¿Qué información debo enviar para soporte financiero?',
            answer:
                'Incluye número de solicitud, fecha del movimiento, valor y cualquier comprobante que ayude a validar el caso.',
          ),
          _FaqItem(
            question: '¿Cuánto tarda la respuesta de facturación?',
            answer:
                'La respuesta inicial suele darse entre 24 y 48 horas hábiles, según el nivel de validación requerido.',
          ),
        ];
      case 'Supervisión y calidad':
        return const [
          _FaqItem(
            question: '¿Cómo reporto una novedad técnica o de calidad?',
            answer:
                'Usa contacto soporte y detalla servicio, fecha, hallazgo y evidencia. Eso permite escalar al equipo técnico correcto.',
          ),
          _FaqItem(
            question: '¿Dónde encuentro el seguimiento de supervisión?',
            answer:
                'Desde Supervisión puedes revisar trazabilidad, actas, acompañamiento técnico y soportes del servicio ejecutado.',
          ),
          _FaqItem(
            question: '¿Qué evidencia debo adjuntar en un caso técnico?',
            answer:
                'Comparte fotos, actas, tiempos, ubicación y cualquier referencia que permita analizar el evento con rapidez.',
          ),
        ];
      default:
        return const [
          _FaqItem(
            question: '¿Cómo registro mi empresa?',
            answer:
                'Desde el menú principal, selecciona Registrarse y sigue el flujo de alta con la información operativa de tu empresa.',
          ),
          _FaqItem(
            question: '¿Cómo solicito un servicio?',
            answer:
                'Desde la pantalla principal o desde Crear solicitud, completa el formulario con alcance, ubicación y urgencia.',
          ),
          _FaqItem(
            question: '¿Cómo contacto soporte?',
            answer:
                'Puedes escribir a soporte@saneapp.com, ir a contacto soporte o usar el centro de soporte para escoger el canal adecuado.',
          ),
        ];
    }
  }

  Future<void> _openEmail(BuildContext context, String? topic) async {
    final emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'soporte@saneapp.com',
      queryParameters: {
        'subject': topic == null
            ? 'Soporte SaneApp'
            : 'Soporte SaneApp - $topic',
        'body': topic == null
            ? 'Hola, tengo una pregunta sobre...'
            : 'Hola, necesito ayuda con el tema: $topic.',
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
    final items = _itemsForTopic(topic);
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: const Text('Preguntas frecuentes'),
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
                  'Base de conocimiento',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  topic == null
                      ? 'Encuentra respuestas rápidas para cuenta, pagos, solicitudes y operación dentro de SaneApp.'
                      : 'Mostrando respuestas priorizadas para el tema: $topic.',
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
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFDCE7DF)),
                ),
                child: ExpansionTile(
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  leading: const Icon(
                    Icons.help_outline_rounded,
                    color: _brandGreenSoft,
                  ),
                  title: Text(
                    item.question,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Text(
                      item.answer,
                      style: const TextStyle(
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Contactar soporte'),
                  onPressed: () => _openEmail(context, topic),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Abrir chat'),
                  onPressed: () => Navigator.of(context).pushNamed(
                    '/live-chat',
                    arguments: topic == null ? null : {'topic': topic},
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});
}
