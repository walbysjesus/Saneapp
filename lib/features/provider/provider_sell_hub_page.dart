import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'provider_publication_matrix.dart';

class ProviderSellHubPage extends StatefulWidget {
  const ProviderSellHubPage({super.key});

  @override
  State<ProviderSellHubPage> createState() => _ProviderSellHubPageState();
}

class _ProviderSellHubPageState extends State<ProviderSellHubPage> {
  static const _brandGreen = Color(0xFF0C4F31);
  static const _brandGreenSoft = Color(0xFF1E7A4B);
  bool _openingFlow = false;

  Future<void> _startPublicationFlow() async {
    if (_openingFlow) {
      return;
    }
    setState(() => _openingFlow = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) {
          return;
        }
        Navigator.pushNamed(
          context,
          '/register',
          arguments: const {'marketplaceIntent': 'sell'},
        );
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = snapshot.data() ?? const <String, dynamic>{};
      if (!mounted) {
        return;
      }

      final role = userData['role']?.toString();
      if (role == 'proveedor') {
        Navigator.pushNamed(
          context,
          userData['profileCompleted'] == true
              ? '/provider-service-create'
              : '/provider-profile-setup',
        );
        return;
      }

      Navigator.pushNamed(
        context,
        '/role-selection',
        arguments: const {'marketplaceIntent': 'sell'},
      );
    } finally {
      if (mounted) {
        setState(() => _openingFlow = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final requiresRegistration = user == null;
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      appBar: AppBar(
        title: const Text('Vender en SaneApp'),
        backgroundColor: _brandGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    requiresRegistration
                        ? 'Explora primero, registrate solo para vender'
                        : 'Marketplace ambiental para publicar servicios',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Publica servicios ambientales con un flujo comercial, no con un formulario frio.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Primero eliges que tipo de servicio quieres vender. Luego seleccionas categoria, subcategoria y completas una ficha tecnica y comercial que realmente sirva para cotizar y cerrar negocios.',
                  style: TextStyle(color: Colors.white70, height: 1.45),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _openingFlow ? null : _startPublicationFlow,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFE168),
                      foregroundColor: const Color(0xFF21303A),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    icon: _openingFlow
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_business_outlined),
                    label: const Text(
                      'INICIAR NUEVA PUBLICACION',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  requiresRegistration
                      ? 'Puedes entrar y explorar sin credenciales. Solo te pediremos cuenta cuando quieras vender o activar una compra.'
                      : 'Ya puedes continuar con tu flujo de publicacion. Si tu perfil de proveedor no esta completo, SaneApp te llevara a terminarlo antes de publicar.',
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _SellHubSectionHeader(
            title: 'Como funciona la publicacion',
            subtitle:
                'El flujo se alinea con una marketplace ambiental: descubrir, estructurar la oferta y despues activar el negocio.',
          ),
          const SizedBox(height: 12),
          const _SellHubStepCard(
            step: '1',
            title: 'Elige que quieres vender',
            description:
                'Selecciona la linea de servicio: servicios ambientales, equipos con operador, emergencias, transporte o supervision tecnica.',
          ),
          const SizedBox(height: 10),
          const _SellHubStepCard(
            step: '2',
            title: 'Selecciona categoria y subcategoria',
            description:
                'La categoria define el mercado donde apareceras y la subcategoria desbloquea la plantilla tecnica adecuada.',
          ),
          const SizedBox(height: 10),
          const _SellHubStepCard(
            step: '3',
            title: 'Completa la ficha comercial',
            description:
                'Cargas precio desde, modalidad, tiempo de respuesta, entregables, cobertura y detalles operativos segun el tipo de servicio.',
          ),
          const SizedBox(height: 18),
          const _SellHubSectionHeader(
            title: 'Que puede publicar un proveedor',
            subtitle:
                'Estas lineas responden a la logica comercial de una marketplace ambiental B2B, no a un catalogo generico.',
          ),
          const SizedBox(height: 12),
          ...marketplaceServiceLines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ServiceLinePreviewCard(line: line),
            ),
          ),
        ],
      ),
    );
  }
}

class _SellHubSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SellHubSectionHeader({required this.title, required this.subtitle});

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
        Text(subtitle, style: const TextStyle(color: Color(0xFF63736C))),
      ],
    );
  }
}

class _SellHubStepCard extends StatelessWidget {
  final String step;
  final String title;
  final String description;

  const _SellHubStepCard({
    required this.step,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F3EC),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              step,
              style: const TextStyle(
                color: Color(0xFF0C4F31),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(color: Color(0xFF63736C), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceLinePreviewCard extends StatelessWidget {
  final MarketplaceServiceLine line;

  const _ServiceLinePreviewCard({required this.line});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3ED),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Icon(line.icon, color: const Color(0xFF1E7A4B)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  line.subtitle,
                  style: const TextStyle(
                    color: Color(0xFF0C4F31),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  line.description,
                  style: const TextStyle(color: Color(0xFF63736C), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}