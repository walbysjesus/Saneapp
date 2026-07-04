import 'package:flutter/material.dart';

class LiveChatScreen extends StatelessWidget {
  const LiveChatScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final topic = _topicFromContext(context);
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: const Text('Chat en línea'),
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
                const Row(
                  children: [
                    Icon(
                      Icons.support_agent_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Atención operativa guiada',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  topic == null
                      ? 'Este canal es ideal para dudas rápidas, bloqueos activos y orientación inmediata sobre el uso de la plataforma.'
                      : 'Estás entrando con contexto para el tema: $topic. Si el caso requiere seguimiento formal, te derivaremos a contacto soporte.',
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
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
                  'Disponibilidad actual',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  topic == null
                      ? 'Actualmente no contamos con asesor en tiempo real dentro de la app.'
                      : 'Actualmente no contamos con asesor en tiempo real dentro de la app para el frente: $topic.',
                  style: const TextStyle(color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Ayuda en línea'),
                          content: Text(
                            topic == null
                                ? 'Por ahora te recomendamos escribir a soporte@saneapp.com o revisar las preguntas frecuentes para resolver tu caso con más rapidez.'
                                : 'Por ahora te recomendamos escalar el caso "$topic" a soporte@saneapp.com o revisar las preguntas frecuentes especializadas.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('Cerrar'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Intentar asistencia'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('Ver FAQ'),
                  onPressed: () => Navigator.of(context).pushNamed(
                    '/faq',
                    arguments: topic == null ? null : {'topic': topic},
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Escalar caso'),
                  onPressed: () => Navigator.of(context).pushNamed(
                    '/contact-support',
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
