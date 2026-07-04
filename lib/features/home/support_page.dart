import 'package:flutter/material.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  static const _brandGreen = Color(0xFF0C4F31);
  static const _brandGreenSoft = Color(0xFF1E7A4B);
  static const _surface = Color(0xFFF6FAF7);
  static const _alertColor = Color(0xFFC24E00);
  static const _infoColor = Color(0xFF3B6EA5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: const Text('Centro de soporte'),
        backgroundColor: _brandGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          const _SupportHero(),
          const SizedBox(height: 18),
          const _SectionHeader(
            title: 'Canales disponibles',
            subtitle:
                'Elige el canal correcto según el nivel de urgencia y el tipo de ayuda que necesitas.',
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _SupportActionCard(
                title: 'Chat en vivo',
                subtitle:
                    'Atención operativa para dudas rápidas y bloqueos activos.',
                icon: Icons.support_agent_outlined,
                accentColor: _brandGreenSoft,
                onTap: () => Navigator.of(context).pushNamed('/live-chat'),
              ),
              _SupportActionCard(
                title: 'Preguntas frecuentes',
                subtitle:
                    'Respuestas listas sobre cuenta, pagos, solicitudes y uso.',
                icon: Icons.help_center_outlined,
                accentColor: _infoColor,
                onTap: () => Navigator.of(context).pushNamed('/faq'),
              ),
              _SupportActionCard(
                title: 'Contacto directo',
                subtitle:
                    'Escala tu caso a soporte cuando necesites seguimiento humano.',
                icon: Icons.mail_outline,
                accentColor: _brandGreen,
                onTap: () =>
                    Navigator.of(context).pushNamed('/contact-support'),
              ),
              _SupportActionCard(
                title: 'Emergencias 24/7',
                subtitle:
                    'Incidentes críticos ambientales con atención inmediata.',
                icon: Icons.crisis_alert_outlined,
                accentColor: _alertColor,
                onTap: () =>
                    Navigator.of(context).pushNamed('/emergency-services'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionHeader(
            title: 'Soporte por tema',
            subtitle:
                'Rutas rápidas para resolver los frentes más comunes dentro del marketplace.',
          ),
          const SizedBox(height: 12),
          _TopicCard(
            title: 'Cuenta y perfil',
            subtitle:
                'Actualización de datos, acceso, verificación y configuración del perfil cliente.',
            icon: Icons.account_circle_outlined,
            accentColor: _brandGreenSoft,
            badge: 'Respuesta estándar < 24h',
            onTap: () => Navigator.of(
              context,
            ).pushNamed('/faq', arguments: {'topic': 'Cuenta y perfil'}),
          ),
          const SizedBox(height: 10),
          _TopicCard(
            title: 'Solicitudes, subastas y ofertas',
            subtitle:
                'Creación, seguimiento, adjudicación, trazabilidad y publicación de requerimientos.',
            icon: Icons.assignment_outlined,
            accentColor: _brandGreen,
            badge: 'Equipo operativo',
            onTap: () => Navigator.of(context).pushNamed(
              '/live-chat',
              arguments: {'topic': 'Solicitudes, subastas y ofertas'},
            ),
          ),
          const SizedBox(height: 10),
          _TopicCard(
            title: 'Pagos y facturación',
            subtitle:
                'Cobros, estados de pago, evidencias administrativas y soporte financiero.',
            icon: Icons.payments_outlined,
            accentColor: _infoColor,
            badge: 'Prioridad media',
            onTap: () => Navigator.of(context).pushNamed(
              '/contact-support',
              arguments: {'topic': 'Pagos y facturación'},
            ),
          ),
          const SizedBox(height: 10),
          _TopicCard(
            title: 'Supervisión y calidad',
            subtitle:
                'Acompañamiento técnico, evidencias, actas y trazabilidad del servicio supervisado.',
            icon: Icons.verified_user_outlined,
            accentColor: _alertColor,
            badge: 'Escalamiento técnico',
            onTap: () => Navigator.of(context).pushNamed(
              '/contact-support',
              arguments: {'topic': 'Supervisión y calidad'},
            ),
          ),
          const SizedBox(height: 20),
          const _SectionHeader(
            title: 'Acuerdos de atención',
            subtitle:
                'Tiempos orientativos para que el usuario entienda qué esperar del soporte.',
          ),
          const SizedBox(height: 12),
          const _SlaCard(),
        ],
      ),
    );
  }
}

class _SupportHero extends StatelessWidget {
  const _SupportHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [SupportPage._brandGreen, SupportPage._brandGreenSoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Centro de soporte SaneApp',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Resuelve incidencias operativas, dudas de cuenta, pagos, solicitudes y soporte técnico desde un solo frente.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroPill(label: 'Atención operativa'),
              _HeroPill(label: 'Escalamiento técnico'),
              _HeroPill(label: 'Emergencias 24/7'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label;

  const _HeroPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class _SupportActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _SupportActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFDCE7DF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: accentColor),
              const SizedBox(height: 14),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String badge;
  final VoidCallback onTap;

  const _TopicCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.badge,
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFDCE7DF)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: accentColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _SlaCard extends StatelessWidget {
  const _SlaCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCE7DF)),
      ),
      child: const Column(
        children: [
          _SlaRow(
            label: 'Chat en vivo',
            value: 'Respuesta estimada: minutos hábiles',
          ),
          _SlaRow(
            label: 'Casos operativos',
            value: 'Respuesta inicial: menos de 24 horas',
          ),
          _SlaRow(
            label: 'Pagos y facturación',
            value: 'Respuesta inicial: 24 a 48 horas hábiles',
          ),
          _SlaRow(
            label: 'Emergencias 24/7',
            value: 'Atención prioritaria inmediata',
          ),
        ],
      ),
    );
  }
}

class _SlaRow extends StatelessWidget {
  final String label;
  final String value;

  const _SlaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: SupportPage._brandGreenSoft,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
