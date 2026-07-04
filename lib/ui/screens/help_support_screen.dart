import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _brandGreen = Color(0xFF0C4F31);
  static const _brandGreenSoft = Color(0xFF1E7A4B);
  static const _surface = Color(0xFFF6FAF7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: const Text('Ayuda y soporte'),
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Necesitas ayuda?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Encuentra respuestas rápidas, escala tu caso y usa el centro de soporte adecuado para cada situación.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SupportShortcutCard(
            icon: Icons.support_agent_outlined,
            title: 'Centro de soporte',
            subtitle:
                'Pantalla principal de soporte con rutas por canal, tema y acuerdos de atención.',
            onTap: () => Navigator.pushNamed(context, '/support'),
          ),
          const SizedBox(height: 12),
          _SupportShortcutCard(
            icon: Icons.help_outline_rounded,
            title: 'Preguntas frecuentes',
            subtitle:
                'Consulta respuestas rápidas sobre cuenta, pagos, solicitudes y operación.',
            onTap: () => Navigator.pushNamed(context, '/faq'),
          ),
          const SizedBox(height: 12),
          _SupportShortcutCard(
            icon: Icons.email_outlined,
            title: 'Contactar soporte',
            subtitle:
                'Escala tu caso a soporte@saneapp.com con seguimiento humano.',
            onTap: () => Navigator.pushNamed(context, '/contact-support'),
          ),
          const SizedBox(height: 12),
          _SupportShortcutCard(
            icon: Icons.chat_bubble_outline,
            title: 'Chat en línea',
            subtitle:
                'Usa este canal para orientación rápida y derivación operativa.',
            onTap: () => Navigator.pushNamed(context, '/live-chat'),
          ),
        ],
      ),
    );
  }
}

class _SupportShortcutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportShortcutCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFDCE7DF)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: HelpSupportScreen._brandGreenSoft.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: HelpSupportScreen._brandGreenSoft),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: HelpSupportScreen._brandGreenSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
